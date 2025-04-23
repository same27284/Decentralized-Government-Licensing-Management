;; Applicant Verification Contract
;; Validates identity of license seekers

(define-data-var admin principal tx-sender)

;; Data structure for applicant information
(define-map applicants
  { applicant-id: (string-ascii 36) }
  {
    principal: principal,
    full-name: (string-ascii 100),
    date-of-birth: (string-ascii 10),
    id-document-hash: (buff 32),
    verified: bool,
    verification-date: (optional uint)
  }
)

;; List of authorized verifiers
(define-map authorized-verifiers principal bool)

;; Add a verifier
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1000))
    (ok (map-set authorized-verifiers verifier true))
  )
)

;; Remove a verifier
(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1001))
    (ok (map-delete authorized-verifiers verifier))
  )
)

;; Submit applicant information
(define-public (submit-applicant-info
    (applicant-id (string-ascii 36))
    (full-name (string-ascii 100))
    (date-of-birth (string-ascii 10))
    (id-document-hash (buff 32)))
  (begin
    (asserts! (is-none (map-get? applicants { applicant-id: applicant-id })) (err u1002))
    (ok (map-set applicants
      { applicant-id: applicant-id }
      {
        principal: tx-sender,
        full-name: full-name,
        date-of-birth: date-of-birth,
        id-document-hash: id-document-hash,
        verified: false,
        verification-date: none
      }
    ))
  )
)

;; Verify an applicant
(define-public (verify-applicant (applicant-id (string-ascii 36)))
  (let ((applicant-data (unwrap! (map-get? applicants { applicant-id: applicant-id }) (err u1003))))
    (begin
      (asserts! (default-to false (map-get? authorized-verifiers tx-sender)) (err u1004))
      (ok (map-set applicants
        { applicant-id: applicant-id }
        (merge applicant-data {
          verified: true,
          verification-date: (some block-height)
        })
      ))
    )
  )
)

;; Check if an applicant is verified
(define-read-only (is-applicant-verified (applicant-id (string-ascii 36)))
  (match (map-get? applicants { applicant-id: applicant-id })
    applicant-data (ok (get verified applicant-data))
    (err u1003)
  )
)

;; Get applicant information
(define-read-only (get-applicant-info (applicant-id (string-ascii 36)))
  (map-get? applicants { applicant-id: applicant-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1005))
    (ok (var-set admin new-admin))
  )
)
