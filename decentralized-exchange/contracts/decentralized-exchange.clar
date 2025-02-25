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