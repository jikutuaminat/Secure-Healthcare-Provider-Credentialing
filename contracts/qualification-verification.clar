;; qualification-verification.clar
;; This contract validates medical degrees and training

;; Define contract owner
(define-data-var contract-owner principal tx-sender)

;; Data structures
(define-map qualifications
  { id: (string-ascii 32) }
  {
    provider-id: (string-ascii 32),
    qualification-type: (string-ascii 32),
    institution: (string-ascii 64),
    date-issued: (string-ascii 10),
    expiration-date: (string-ascii 10),
    verified: bool,
    verified-by: principal,
    verified-at: uint,
    created-at: uint,
    updated-at: uint
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_EXISTS u2)
(define-constant ERR_NOT_FOUND u3)
(define-constant ERR_INVALID_INPUT u4)

;; Authorization check
(define-private (is-authorized)
  (is-eq tx-sender (var-get contract-owner)))

;; Public functions
(define-public (add-qualification
                (id (string-ascii 32))
                (provider-id (string-ascii 32))
                (qualification-type (string-ascii 32))
                (institution (string-ascii 64))
                (date-issued (string-ascii 10))
                (expiration-date (string-ascii 10)))
  (begin
    (asserts! (is-authorized) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? qualifications { id: id })) (err ERR_ALREADY_EXISTS))

    (map-set qualifications
      { id: id }
      {
        provider-id: provider-id,
        qualification-type: qualification-type,
        institution: institution,
        date-issued: date-issued,
        expiration-date: expiration-date,
        verified: false,
        verified-by: tx-sender,
        verified-at: u0,
        created-at: block-height,
        updated-at: block-height
      }
    )
    (ok id)
  )
)

(define-public (verify-qualification (id (string-ascii 32)))
  (let ((qualification (unwrap! (map-get? qualifications { id: id }) (err ERR_NOT_FOUND))))
    (begin
      (asserts! (is-authorized) (err ERR_UNAUTHORIZED))

      (map-set qualifications
        { id: id }
        (merge qualification
          {
            verified: true,
            verified-by: tx-sender,
            verified-at: block-height,
            updated-at: block-height
          }
        )
      )
      (ok id)
    )
  )
)

(define-public (update-qualification
                (id (string-ascii 32))
                (qualification-type (string-ascii 32))
                (institution (string-ascii 64))
                (date-issued (string-ascii 10))
                (expiration-date (string-ascii 10)))
  (let ((qualification (unwrap! (map-get? qualifications { id: id }) (err ERR_NOT_FOUND))))
    (begin
      (asserts! (is-authorized) (err ERR_UNAUTHORIZED))

      (map-set qualifications
        { id: id }
        (merge qualification
          {
            qualification-type: qualification-type,
            institution: institution,
            date-issued: date-issued,
            expiration-date: expiration-date,
            updated-at: block-height
          }
        )
      )
      (ok id)
    )
  )
)

(define-read-only (get-qualification (id (string-ascii 32)))
  (ok (map-get? qualifications { id: id })))

