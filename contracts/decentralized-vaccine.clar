;; decentralized-vaccine.clar

(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-DATA-EXISTS (err u3))
(define-constant ERR-INVALID-DATA (err u4))
(define-constant ERR-NOT-FOUND (err u5))

;; Custom validation function for string length
(define-private (string-longer-than 
    (input (string-ascii 1000)) 
    (min-length uint)
) 
    (> (len input) min-length)
)

;; Data structures
(define-map genome-submissions 
    {researcher: principal, genome-id: (string-ascii 50)} 
    {
        pathogen: (string-ascii 100),
        genome-data: (string-ascii 1000),
        research-center: (string-ascii 100),
        associated-researchers: (list 10 principal),
        submitted-at: uint
    }
)

;; Track unique genome IDs globally
(define-map global-genome-ids 
    (string-ascii 50) 
    bool
)

;; Track researcher's genome submissions
(define-map researcher-submissions 
    principal 
    (list 50 (string-ascii 50))
)

;; Submit genome data
(define-public (submit-genome-data 
    (genome-id (string-ascii 50))
    (pathogen (string-ascii 100))
    (genome-data (string-ascii 1000))
    (research-center (string-ascii 100))
    (associated-researchers (list 10 principal))
)
    (begin
        ;; Validate input data
        (try! (validate-input genome-id pathogen genome-data research-center))
        
        ;; Check for duplicate genome ID
        (asserts! (is-none (map-get? global-genome-ids genome-id)) ERR-DATA-EXISTS)
        
        ;; Store genome submission
        (map-set genome-submissions 
            {researcher: tx-sender, genome-id: genome-id}
            {
                pathogen: pathogen,
                genome-data: genome-data,
                research-center: research-center,
                associated-researchers: associated-researchers,
                submitted-at: block-height
            }
        )
        
        ;; Mark genome ID as used
        (map-set global-genome-ids genome-id true)
        
        ;; Update researcher's submission list
        (let 
            (
                (current-submissions 
                    (default-to 
                        (list) 
                        (map-get? researcher-submissions tx-sender)
                    )
                )
                (updated-submissions 
                    (unwrap! 
                        (as-max-len? 
                            (concat current-submissions (list genome-id)) 
                            u50
                        ) 
                        ERR-NOT-AUTHORIZED
                    )
                )
            )
            (map-set researcher-submissions tx-sender updated-submissions)
        )
        
        (ok true)
    )
)

;; Validate submission input
(define-private (validate-input 
    (genome-id (string-ascii 50))
    (pathogen (string-ascii 100))
    (genome-data (string-ascii 1000))
    (research-center (string-ascii 100))
) 
    (begin
        ;; Use custom validation function with uint comparisons
        (asserts! (string-longer-than genome-id u0) ERR-INVALID-DATA)
        (asserts! (string-longer-than pathogen u0) ERR-INVALID-DATA)
        (asserts! (string-longer-than genome-data u10) ERR-INVALID-DATA)
        (asserts! (string-longer-than research-center u0) ERR-INVALID-DATA)
        (ok true)
    )
)

;; Retrieve genome submission
(define-read-only (get-genome-submission 
    (researcher principal)
    (genome-id (string-ascii 50))
)
    (map-get? genome-submissions {researcher: researcher, genome-id: genome-id})
)

;; List all submissions by a researcher
(define-read-only (get-researcher-submissions 
    (researcher principal)
)
    (map-get? researcher-submissions researcher)
)

;; Optional: Count submissions by a researcher
(define-read-only (count-researcher-submissions 
    (researcher principal)
)
    (match (map-get? researcher-submissions researcher)
        submissions (len submissions)
        u0
    )
)
