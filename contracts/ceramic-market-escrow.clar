;; CeramicMarket Escrow Exchange
;; A decentralized marketplace for ceramic tiles with escrow functionality

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-found (err u201))
(define-constant err-unauthorized (err u202))
(define-constant err-invalid-state (err u203))
(define-constant err-insufficient-payment (err u204))

(define-map tile-listings
  { listing-id: uint }
  {
    seller: principal,
    tile-type: (string-ascii 50),
    quantity: uint,
    price-per-unit: uint,
    total-price: uint,
    status: (string-ascii 20),
    buyer: (optional principal),
    created-at: uint
  }
)

(define-map escrow-deposits
  { listing-id: uint }
  {
    buyer: principal,
    amount: uint,
    deposited-at: uint
  }
)

(define-data-var next-listing-id uint u1)
(define-data-var platform-fee-rate uint u250) ;; 2.5%

;; Create a new tile listing
(define-public (create-listing 
  (tile-type (string-ascii 50))
  (quantity uint)
  (price-per-unit uint))
  (let ((listing-id (var-get next-listing-id))
        (total-price (* quantity price-per-unit)))
    (map-set tile-listings
      { listing-id: listing-id }
      {
        seller: tx-sender,
        tile-type: tile-type,
        quantity: quantity,
        price-per-unit: price-per-unit,
        total-price: total-price,
        status: "active",
        buyer: none,
        created-at: stacks-block-height
      }
    )
    (var-set next-listing-id (+ listing-id u1))
    (ok listing-id)))

;; Place order with escrow deposit
(define-public (place-order (listing-id uint))
  (let ((listing (unwrap! (map-get? tile-listings { listing-id: listing-id }) err-not-found)))
    (asserts! (is-eq (get status listing) "active") err-invalid-state)
    (asserts! (not (is-eq tx-sender (get seller listing))) err-unauthorized)
    (match (stx-transfer? (get total-price listing) tx-sender (as-contract tx-sender))
      success (begin
        (map-set escrow-deposits
          { listing-id: listing-id }
          {
            buyer: tx-sender,
            amount: (get total-price listing),
            deposited-at: stacks-block-height
          }
        )
        (map-set tile-listings
          { listing-id: listing-id }
          (merge listing { status: "pending", buyer: (some tx-sender) })
        )
        (ok true))
      error err-insufficient-payment)))

;; Complete order and release escrow
(define-public (complete-order (listing-id uint))
  (let ((listing (unwrap! (map-get? tile-listings { listing-id: listing-id }) err-not-found))
        (escrow (unwrap! (map-get? escrow-deposits { listing-id: listing-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get seller listing)) err-unauthorized)
    (asserts! (is-eq (get status listing) "pending") err-invalid-state)
    (let ((platform-fee (/ (* (get amount escrow) (var-get platform-fee-rate)) u10000))
          (seller-amount (- (get amount escrow) platform-fee)))
      (try! (as-contract (stx-transfer? seller-amount tx-sender (get seller listing))))
      (try! (as-contract (stx-transfer? platform-fee tx-sender contract-owner)))
      (map-set tile-listings
        { listing-id: listing-id }
        (merge listing { status: "completed" })
      )
      (map-delete escrow-deposits { listing-id: listing-id })
      (ok true))))

;; Cancel order and refund buyer
(define-public (cancel-order (listing-id uint))
  (let ((listing (unwrap! (map-get? tile-listings { listing-id: listing-id }) err-not-found))
        (escrow (unwrap! (map-get? escrow-deposits { listing-id: listing-id }) err-not-found)))
    (asserts! (or (is-eq tx-sender (get seller listing)) 
                  (is-eq tx-sender (get buyer escrow))) err-unauthorized)
    (asserts! (is-eq (get status listing) "pending") err-invalid-state)
    (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get buyer escrow))))
    (map-set tile-listings
      { listing-id: listing-id }
      (merge listing { status: "cancelled", buyer: none })
    )
    (map-delete escrow-deposits { listing-id: listing-id })
    (ok true)))

;; Get listing information
(define-read-only (get-listing (listing-id uint))
  (map-get? tile-listings { listing-id: listing-id }))

;; Get escrow information
(define-read-only (get-escrow (listing-id uint))
  (map-get? escrow-deposits { listing-id: listing-id }))

;; Get platform fee rate
(define-read-only (get-platform-fee-rate)
  (var-get platform-fee-rate))

;; Get next listing ID
(define-read-only (get-next-listing-id)
  (var-get next-listing-id))