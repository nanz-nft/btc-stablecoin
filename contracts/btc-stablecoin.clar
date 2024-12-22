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