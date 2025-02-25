;; Define constants for contract addresses and token types
(define-constant WRAPPED-BTC (as-contract 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.wrapped-btc))
(define-constant STACKS-TOKEN (as-contract 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.stacks-token))
(define-constant FEE-RATE u500) ;; 0.5% trading fee (500 basis points)
(define-constant ADMIN 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM) ;; Admin address

(define-map orders
  { sender: principal, amount-in: uint, token-in: principal, token-out: principal } ;; Order details
  { timestamp: uint }                                                              ;; Order timestamp
)

;; Error codes
(define-constant ERR-UNAUTHORIZED u401)
(define-constant ERR-NOT-FOUND u404)
(define-constant ERR-INSUFFICIENT-BALANCE u500)
(define-constant ERR-INVALID-TOKEN u501)

;; Data variables
(define-data-var liquidity-btc uint u0)
(define-data-var liquidity-stx uint u0)
(define-data-var collected-fees uint u0)
(define-data-var order-counter uint u0)


;; Read-only functions

;; Get current liquidity amounts
(define-read-only (get-liquidity)
  {
    btc: (var-get liquidity-btc),
    stx: (var-get liquidity-stx)
  }
)


;; Get collected fees
(define-read-only (get-fees)
  (var-get collected-fees)
)


;; Calculate the price for a given input amount and tokens
(define-read-only (get-swap-price (amount-in uint) (token-in principal) (token-out principal))
  (let (
    (reserve-in (if (is-eq token-in WRAPPED-BTC) (var-get liquidity-btc) (var-get liquidity-stx)))
    (reserve-out (if (is-eq token-out WRAPPED-BTC) (var-get liquidity-btc) (var-get liquidity-stx)))
    (fee-amount (/ (* amount-in FEE-RATE) u100000))
    (amount-in-with-fee (- amount-in fee-amount))
  )
  (if (or (is-eq reserve-in u0) (is-eq reserve-out u0))
    u0
    (/ (* amount-in-with-fee reserve-out) (+ reserve-in amount-in-with-fee))
  ))
)

;; Check if token is supported
(define-read-only (is-supported-token (token principal))
  (or (is-eq token WRAPPED-BTC) (is-eq token STACKS-TOKEN))
)
