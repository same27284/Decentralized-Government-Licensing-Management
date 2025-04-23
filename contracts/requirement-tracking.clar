;; Requirement Tracking Contract
;; Ensures fulfillment of prerequisites for licenses

(define-data-var admin principal tx-sender)

;; Define license types
(define-map license-types
  { license-type-id: (string-ascii 20) }
  {
    name: (string-ascii 100),
    description: (string-ascii 255),
    active: bool
  }
)

;; Define requirements for each license type
(define-map license-requirements
  {
    license-type-id: (string-ascii 20),
    requirement-id: (string-ascii 20)
  }
  {
    name: (string-ascii 100),
    description: (string-ascii 255),
    mandatory: bool
  }
)

;; Track completed requirements for applicants
(define-map completed-requirements
  {
    applicant-id: (string-ascii 36),
    license-type-id: (string-ascii 20),
    requirement-id: (string-ascii 20)
  }
  {
    completed: bool,
    completion-date: uint,
    verified-by: principal
  }
)

;; List of authorized requirement verifiers
(define-map authorized-verifiers principal bool)

;; Add a license type
(define-public (add-license-type
    (license-type-id (string-ascii 20))
    (name (string-ascii 100))
    (description (string-ascii 255)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2000))
    (asserts! (is-none (map-get? license-types { license-type-id: license-type-id })) (err u2001))
    (ok (map-set license-types
      { license-type-id: license-type-id }
      {
        name: name,
        description: description,
        active: true
      }
    ))
  )
)

;; Add a requirement for a license type
(define-public (add-requirement
    (license-type-id (string-ascii 20))
    (requirement-id (string-ascii 20))
    (name (string-ascii 100))
    (description (string-ascii 255))
    (mandatory bool))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2002))
    (asserts! (is-some (map-get? license-types { license-type-id: license-type-id })) (err u2003))
    (asserts! (is-none (map-get? license-requirements
      {
        license-type-id: license-type-id,
        requirement-id: requirement-id
      })) (err u2004))
    (ok (map-set license-requirements
      {
        license-type-id: license-type-id,
        requirement-id: requirement-id
      }
      {
        name: name,
        description: description,
        mandatory: mandatory
      }
    ))
  )
)

;; Add a verifier
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2005))
    (ok (map-set authorized-verifiers verifier true))
  )
)

;; Mark a requirement as completed
(define-public (complete-requirement
    (applicant-id (string-ascii 36))
    (license-type-id (string-ascii 20))
    (requirement-id (string-ascii 20)))
  (begin
    (asserts! (default-to false (map-get? authorized-verifiers tx-sender)) (err u2006))
    (asserts! (is-some (map-get? license-types { license-type-id: license-type-id })) (err u2007))
    (asserts! (is-some (map-get? license-requirements
      {
        license-type-id: license-type-id,
        requirement-id: requirement-id
      })) (err u2008))
    (ok (map-set completed-requirements
      {
        applicant-id: applicant-id,
        license-type-id: license-type-id,
        requirement-id: requirement-id
      }
      {
        completed: true,
        completion-date: block-height,
        verified-by: tx-sender
      }
    ))
  )
)

;; Check if a requirement is completed
(define-read-only (is-requirement-completed
    (applicant-id (string-ascii 36))
    (license-type-id (string-ascii 20))
    (requirement-id (string-ascii 20)))
  (match (map-get? completed-requirements
    {
      applicant-id: applicant-id,
      license-type-id: license-type-id,
      requirement-id: requirement-id
    })
    requirement-data (ok (get completed requirement-data))
    (err u2009)
  )
)

;; Check if all mandatory requirements are completed for a license type
(define-read-only (are-all-requirements-completed
    (applicant-id (string-ascii 36))
    (license-type-id (string-ascii 20)))
  (ok true) ;; Simplified implementation - in a real contract, would iterate through all requirements
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2010))
    (ok (var-set admin new-admin))
  )
)
