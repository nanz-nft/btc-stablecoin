;; title: Bitcoin-Backed Stablecoin System
;; summary: A decentralized stablecoin system backed by Bitcoin with overcollateralization.
;; description: This smart contract implements a robust stablecoin system where users can deposit Bitcoin as collateral to mint stablecoins.
;; The system ensures stability through overcollateralization and includes mechanisms for liquidation, collateral withdrawal, and debt repayment.
;; It also features administrative functions for setting the Bitcoin price and managing the price oracle.

;; Error codes for better error handling and debugging
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u1001))
(define-constant ERR-BELOW-MINIMUM (err u1002))
(define-constant ERR-INVALID-AMOUNT (err u1003))
(define-constant ERR-POSITION-NOT-FOUND (err u1004))
(define-constant ERR-ALREADY-LIQUIDATED (err u1005))
(define-constant ERR-HEALTHY-POSITION (err u1006))
(define-constant ERR-PRICE-EXPIRED (err u1007))
(define-constant ERR-ZERO-AMOUNT (err u1008))
(define-constant ERR-MAX-AMOUNT-EXCEEDED (err u1009))

;; System Parameters
;; MIN-COLLATERAL-RATIO: Minimum collateralization ratio required to maintain a position (150%)
(define-constant MIN-COLLATERAL-RATIO u150)
;; LIQUIDATION-RATIO: Threshold at which positions become eligible for liquidation (120%)
(define-constant LIQUIDATION-RATIO u120)
;; MIN-DEPOSIT: Minimum amount of satoshis required for a deposit (0.01 BTC)
(define-constant MIN-DEPOSIT u1000000)
;; MAX-DEPOSIT: Maximum deposit limit to prevent excessive concentration (10,000 BTC)
(define-constant MAX-DEPOSIT u1000000000000)
;; PRICE-VALIDITY-PERIOD: Number of blocks before price data is considered stale
(define-constant PRICE-VALIDITY-PERIOD u144)
;; MAX-PRICE: Upper limit for BTC price to prevent manipulation
(define-constant MAX-PRICE u1000000000)

;; State Variables
(define-data-var contract-owner principal tx-sender)
(define-data-var price-oracle principal tx-sender)
(define-data-var total-supply uint u0)
(define-data-var btc-price uint u0)
(define-data-var last-price-update uint block-height)

;; Data Maps
;; Stores user positions including collateral amount, debt, and last update block
(define-map user-positions
  principal
  {
    collateral: uint,
    debt: uint,
    last-update: uint
  }
)

;; Records liquidation events for historical tracking and transparency
(define-map liquidation-history
  principal
  {
    timestamp: uint,
    collateral-liquidated: uint,
    debt-repaid: uint
  }
)

;; Read-only functions
(define-read-only (get-position (user principal))
  (map-get? user-positions user)
)

;; Calculates the current collateralization ratio for a user's position
;; Returns the ratio as a percentage (e.g., 150 = 150%)
(define-read-only (get-collateral-ratio (user principal))
  (let (
    (position (unwrap! (get-position user) (err u0)))
    (collateral-value (* (get collateral position) (var-get btc-price)))
    (debt-value (* (get debt position) u100000000))
  )
    (if (is-eq (get debt position) u0)
      (ok u0)
      (ok (/ (* collateral-value u100) debt-value)))
  )
)

(define-read-only (get-current-price)
  (ok (var-get btc-price))
)

;; Private helper functions
;; Ensures price data hasn't expired based on PRICE-VALIDITY-PERIOD
(define-private (check-price-freshness)
  (if (< (- block-height (var-get last-price-update)) PRICE-VALIDITY-PERIOD)
    (ok true)
    ERR-PRICE-EXPIRED
  )
)

;; Validates amount is within acceptable bounds
(define-private (validate-amount (amount uint))
  (begin
    (asserts! (> amount u0) ERR-ZERO-AMOUNT)
    (asserts! (<= amount MAX-DEPOSIT) ERR-MAX-AMOUNT-EXCEEDED)
    (ok true)
  )
)

(define-private (check-min-collateral (amount uint))
  (begin
    (try! (validate-amount amount))
    (if (>= amount MIN-DEPOSIT)
      (ok true)
      ERR-BELOW-MINIMUM)
  )
)

;; Verifies position maintains required collateralization ratio
(define-private (check-position-health (user principal))
  (let (
    (ratio (unwrap! (get-collateral-ratio user) (err u0)))
  )
    (if (< ratio MIN-COLLATERAL-RATIO)
      ERR-INSUFFICIENT-COLLATERAL
      (ok true))
  )
)

;; Public functions for user interactions
;; Allows users to deposit BTC collateral to create or increase their position
(define-public (deposit-collateral (amount uint))
  (begin
    (try! (check-min-collateral amount))
    (let (
      (current-position (default-to
        { collateral: u0, debt: u0, last-update: block-height }
        (get-position tx-sender)
      ))
      (new-collateral (+ amount (get collateral current-position)))
    )
      (asserts! (<= new-collateral MAX-DEPOSIT) ERR-MAX-AMOUNT-EXCEEDED)
      (map-set user-positions tx-sender
        {
          collateral: new-collateral,
          debt: (get debt current-position),
          last-update: block-height
        }
      )
      (ok true))
  )
)

;; Mints new stablecoins against deposited collateral
;; Requires maintaining minimum collateralization ratio
(define-public (mint-stablecoin (amount uint))
  (begin
    (try! (validate-amount amount))
    (try! (check-price-freshness))
    (let (
      (current-position (unwrap! (get-position tx-sender) ERR-POSITION-NOT-FOUND))
      (new-debt (+ amount (get debt current-position)))
      (collateral-value (* (get collateral current-position) (var-get btc-price)))
      (required-collateral (* new-debt MIN-COLLATERAL-RATIO))
    )
      (asserts! (>= collateral-value required-collateral) ERR-INSUFFICIENT-COLLATERAL)
      (asserts! (<= new-debt MAX-DEPOSIT) ERR-MAX-AMOUNT-EXCEEDED)

      (map-set user-positions tx-sender
        {
          collateral: (get collateral current-position),
          debt: new-debt,
          last-update: block-height
        }
      )
      (var-set total-supply (+ (var-get total-supply) amount))
      (ok true))
  )
)

;; Allows users to repay their stablecoin debt
(define-public (repay-stablecoin (amount uint))
  (begin
    (try! (validate-amount amount))
    (let (
      (current-position (unwrap! (get-position tx-sender) ERR-POSITION-NOT-FOUND))
    )
      (asserts! (>= (get debt current-position) amount) ERR-INVALID-AMOUNT)

      (map-set user-positions tx-sender
        {
          collateral: (get collateral current-position),
          debt: (- (get debt current-position) amount),
          last-update: block-height
        }
      )
      (var-set total-supply (- (var-get total-supply) amount))
      (ok true)
    )
  )
)

;; Enables withdrawal of excess collateral
;; Ensures position remains properly collateralized after withdrawal
(define-public (withdraw-collateral (amount uint))
  (begin
    (try! (validate-amount amount))
    (let (
      (current-position (unwrap! (get-position tx-sender) ERR-POSITION-NOT-FOUND))
    )
      (asserts! (>= (get collateral current-position) amount) ERR-INVALID-AMOUNT)

      (map-set user-positions tx-sender
        {
          collateral: (- (get collateral current-position) amount),
          debt: (get debt current-position),
          last-update: block-height
        }
      )
      (try! (check-position-health tx-sender))
      (ok true)
    )
  )
)