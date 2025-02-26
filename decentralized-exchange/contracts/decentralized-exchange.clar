;; Define constants for contract addresses and token types
(define-constant WRAPPED-BTC (as-contract 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.wrapped-btc))
(define-constant STACKS-TOKEN (as-contract 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.stacks-token))
(define-constant FEE-RATE u500) ;; 0.5% trading fee (500 basis points)
(define-constant ADMIN 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM) ;; Admin address



;; LP Token Constants
(define-constant LP-TOKEN-NAME "LP-BTC-STX")
(define-constant LP-TOKEN-SYMBOL "LPBS")

(define-map orders
  { sender: principal, amount-in: uint, token-in: principal, token-out: principal } ;; Order details
  { timestamp: uint }                                                              ;; Order timestamp
)

;; Error codes
(define-constant ERR-UNAUTHORIZED u401)
(define-constant ERR-NOT-FOUND u404)
(define-constant ERR-INSUFFICIENT-BALANCE u500)
(define-constant ERR-INVALID-TOKEN u501)
(define-constant ERR-EXPIRED u502)
(define-constant ERR-SLIPPAGE-TOO-HIGH u503)
(define-constant ERR-MINIMUM-AMOUNT u504)
(define-constant ERR-FLASH-LOAN-NOT-REPAID u505)

;; Data variables
(define-data-var liquidity-btc uint u0)
(define-data-var liquidity-stx uint u0)
(define-data-var collected-fees uint u0)
(define-data-var order-counter uint u0)
(define-data-var total-lp-tokens uint u0)
(define-data-var protocol-fee-percent uint u10) ;; 10% of collected fees go to protocol
(define-data-var min-liquidity uint u1000) ;; Minimum liquidity to prevent price manipulation
(define-data-var paused bool false)
(define-data-var oracle-price-btc-stx uint u0) ;; Last oracle price in STX per BTC


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

;; Get order details
(define-read-only (get-order (sender principal) (amount-in uint) (token-in principal) (token-out principal))
  (map-get? orders { sender: sender, amount-in: amount-in, token-in: token-in, token-out: token-out })
)


(define-map lp-balances 
  { owner: principal } 
  { amount: uint }
)

(define-map limit-orders 
  { id: uint } 
  { 
    sender: principal, 
    token-in: principal, 
    token-out: principal, 
    amount-in: uint, 
    min-amount-out: uint, 
    expires-at: uint 
  }
)

(define-map flash-loans 
  { id: uint } 
  { 
    borrower: principal, 
    token: principal, 
    amount: uint, 
    block: uint, 
    repaid: bool 
  }
)

(define-map allowed-tokens
  { token: principal }
  { enabled: bool }
)


(define-map user-settings
  { user: principal }
  { 
    default-slippage: uint, 
    auto-claim-rewards: bool 
  }
)


;; Get total LP tokens supply
(define-read-only (get-total-lp-supply)
  (var-get total-lp-tokens)
)

;; Get limit order details
(define-read-only (get-limit-order (id uint))
  (map-get? limit-orders { id: id })
)


;; Get current oracle price
(define-read-only (get-oracle-price)
  (var-get oracle-price-btc-stx)
)

;; Check if contract is paused
(define-read-only (is-paused)
  (var-get paused)
)


;; Update oracle price (admin only)
(define-public (update-oracle-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender ADMIN) (err ERR-UNAUTHORIZED))
    (var-set oracle-price-btc-stx new-price)
    (ok new-price)
  )
)

;; Pause or unpause the contract (admin only)
(define-public (set-paused (new-status bool))
  (begin
    (asserts! (is-eq tx-sender ADMIN) (err ERR-UNAUTHORIZED))
    (var-set paused new-status)
    (ok new-status)
  )
)

;; Update user settings
(define-public (update-user-settings (default-slippage uint) (auto-claim-rewards bool))
  (begin
    (map-set user-settings
      { user: tx-sender }
      { 
        default-slippage: default-slippage, 
        auto-claim-rewards: auto-claim-rewards 
      }
    )
    (ok true)
  )
)

;; Helper function to determine if it's time for auto-distribution
(define-read-only (is-auto-distribution-time)
  (is-eq (mod stacks-block-height u1440) u0) ;; Approximately daily on STX blockchain
)

;; Helper function to record LP rewards
(define-private (record-lp-rewards (amount uint))
  (let (
    (total-lp (var-get total-lp-tokens))
  )
    ;; We're not actually distributing here, just recording
    ;; In a real contract, we would iterate through LP holders
    ;; For simplicity, we're just acknowledging the amount
    (ok amount)
  )
)

(define-private (abs (a int))
  (if (< a 0)
    (* a -1)
    a
  )
)


;; Initialize allowed tokens (admin only)
(define-public (initialize-allowed-tokens)
  (begin
    (asserts! (is-eq tx-sender ADMIN) (err ERR-UNAUTHORIZED))
    (map-set allowed-tokens { token: WRAPPED-BTC } { enabled: true })
    (map-set allowed-tokens { token: STACKS-TOKEN } { enabled: true })
    (ok true)
  )
)