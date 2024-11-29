;; Mental Health Anonymous Support Network Smart Contract 
;; Version: 2.0.0

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-ALREADY-MEMBER (err u101))
(define-constant ERR-NOT-MEMBER (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-SUPPORT-REQUEST-NOT-FOUND (err u104))
(define-constant ERR-INVALID-RATING (err u105))
(define-constant ERR-CANNOT-RATE-SELF (err u106))
(define-constant ERR-ALREADY-RATED (err u107))


;; Member Storage
(define-map Members
  principal
  {
    is-verified: bool,
    support-credits: uint,
    total-contributions: uint,
    support-ratings: (list 10 uint),
    average-rating: uint,
    specializations: (list 5 (string-ascii 50)),
    last-active: uint
  }
)


;; Support Requests
(define-map SupportRequests
  uint
  {
    requester: principal,
    request-type: (string-ascii 50),
    anonymity-level: uint,
    status: (string-ascii 20),
    assigned-supporter: (optional principal),
    emergency-flag: bool,
    interaction-logs: (list 10 (string-ascii 100))
  }
)

;; Support Interaction Ratings
(define-map SupportInteractionRatings
  {request-id: uint, rater: principal}
  {
    rating: uint,
    feedback: (string-ascii 200)
  }
)

;; Global counters and variables
(define-data-var total-members uint u0)
(define-data-var support-request-counter uint u0)
(define-data-var emergency-support-fund uint u1000) ;; Initial emergency fund

;; Add Specialization
(define-public (add-specialization 
  (specialization (string-ascii 50))
)
  (let 
    (
      (current-member (unwrap! (map-get? Members tx-sender) ERR-NOT-MEMBER))
      (current-specializations (get specializations current-member))
    )
    (asserts! (get is-verified current-member) ERR-UNAUTHORIZED)
    (asserts! (< (len current-specializations) u5) (err u108)) ;; Max 5 specializations
    
    (map-set Members 
      tx-sender 
      (merge current-member { 
        specializations: (unwrap! (as-max-len? (append current-specializations specialization) u5) (err u109))
      })
    )
    (ok true)
  )
)


;; Emergency Support Request
(define-public (create-emergency-support-request 
  (request-type (string-ascii 50))
)
  (let 
    (
      (request-id (var-get support-request-counter))
      (member (unwrap! (map-get? Members tx-sender) ERR-NOT-MEMBER))
      (emergency-fund (var-get emergency-support-fund))
    )
    (asserts! (get is-verified member) ERR-UNAUTHORIZED)
    
    ;; Check if emergency fund is sufficient
    (asserts! (> emergency-fund u0) (err u110))
    
    (map-set SupportRequests 
      request-id 
      {
        requester: tx-sender,
        request-type: request-type,
        anonymity-level: u3, ;; Highest anonymity
        status: "EMERGENCY_PENDING",
        assigned-supporter: none,
        emergency-flag: true,
        interaction-logs: (list)
      }
    )


 ;; Reduce emergency fund
    (var-set emergency-support-fund (- emergency-fund u100))
    (var-set support-request-counter (+ request-id u1))
    (ok request-id)
  )
)


;; Supporter Rating System
(define-public (rate-support-interaction 
  (request-id uint)
  (rating uint)
  (feedback (string-ascii 200))
)
  (let 
    (
      (request (unwrap! (map-get? SupportRequests request-id) ERR-SUPPORT-REQUEST-NOT-FOUND))
      (assigned-supporter (unwrap! (get assigned-supporter request) (err u111)))
    )
    ;; Validate rating
    (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-RATING)
    (asserts! (not (is-eq tx-sender assigned-supporter)) ERR-CANNOT-RATE-SELF)


 ;; Prevent multiple ratings
    (asserts! 
      (is-none (map-get? SupportInteractionRatings {request-id: request-id, rater: tx-sender})) 
      ERR-ALREADY-RATED
    )
