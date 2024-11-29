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

