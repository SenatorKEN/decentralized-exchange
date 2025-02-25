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
