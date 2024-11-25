;; Decentralized Vaccine Development Network Smart Contract

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INVALID-DATA (err u2))
(define-constant ERR-DATA-EXISTS (err u3))
(define-constant ERR-DATA-NOT-FOUND (err u4))

;; Data storage for genome research submissions
(define-map genome-submissions
  { researcher: principal, 
    genome-id: (string-ascii 50) }
  { 
    parasite-type: (string-ascii 100),
    genome-data: (string-ascii 5000),
    submission-timestamp: uint,
    research-institution: (string-ascii 200),
    access-permissions: (list 10 principal)
  }
)

;; Track total number of genome submissions
(define-data-var total-submissions uint u0)

;; Register a new genome submission
(define-public (submit-genome-data
  (genome-id (string-ascii 50))
  (parasite-type (string-ascii 100))
  (genome-data (string-ascii 5000))
  (research-institution (string-ascii 200))
  (access-permissions (list 10 principal))
)
  (begin
    ;; Validate submission data
    (asserts! (> (len genome-id) u0) ERR-INVALID-DATA)
    (asserts! (> (len genome-data) u0) ERR-INVALID-DATA)
    
    ;; Check if genome submission already exists
    (asserts! 
      (is-none (map-get? genome-submissions { researcher: tx-sender, genome-id: genome-id })) 
      ERR-DATA-EXISTS
    )
    
    ;; Store genome submission
    (map-set genome-submissions 
      { researcher: tx-sender, genome-id: genome-id }
      { 
        parasite-type: parasite-type,
        genome-data: genome-data,
        submission-timestamp: block-height,
        research-institution: research-institution,
        access-permissions: access-permissions
      }
    )
    
    ;; Increment total submissions
    (var-set total-submissions (+ (var-get total-submissions) u1))
    
    (ok true)
  )
)

;; Retrieve genome submission data
(define-read-only (get-genome-submission 
  (researcher principal)
  (genome-id (string-ascii 50))
)
  (map-get? genome-submissions { researcher: researcher, genome-id: genome-id })
)

;; Update access permissions for a genome submission
(define-public (update-access-permissions
  (genome-id (string-ascii 50))
  (new-permissions (list 10 principal))
)
  (let ((current-submission (map-get? genome-submissions { researcher: tx-sender, genome-id: genome-id })))
    (match current-submission
      submission
        (begin
          (map-set genome-submissions 
            { researcher: tx-sender, genome-id: genome-id }
            (merge submission { access-permissions: new-permissions })
          )
          (ok true)
        )
      ERR-DATA-NOT-FOUND
    )
  )
)

;; Get total number of genome submissions
(define-read-only (get-total-submissions)
  (var-get total-submissions)
)

;; Optional: Remove genome submission (only by original submitter)
(define-public (remove-genome-submission (genome-id (string-ascii 50)))
  (begin
    (asserts! 
      (is-some (map-get? genome-submissions { researcher: tx-sender, genome-id: genome-id }))
      ERR-DATA-NOT-FOUND
    )
    
    (map-delete genome-submissions { researcher: tx-sender, genome-id: genome-id })
    (var-set total-submissions (- (var-get total-submissions) u1))
    
    (ok true)
  )
)
