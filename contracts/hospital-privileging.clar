;; hospital-privileging.clar
;; This contract tracks approved procedures by institution

;; Define contract owner
(define-data-var contract-owner principal tx-sender)

;; Data structures
(define-map privileges
  { id: (string-ascii 32) }
  {
    provider-id: (string-ascii 32),
    hospital-id: (string-ascii 32),
    procedure-code: (string-ascii 16),
    granted-date: (string-ascii 10),
    expiration-date: (string-ascii 10),
    status: (string-ascii 16),
    approved-by: principal,
    created-at: uint,
    updated-at: uint
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_EXISTS u2)
(define-constant ERR_NOT_FOUND u3)
(define-constant ERR_INVALID_INPUT u4)

;; Status constants
(define-constant STATUS_ACTIVE "active")
(define-constant STATUS_PENDING "pending")
(define-constant STATUS_SUSPENDED "suspended")
(define-constant STATUS_REVOKED "revoked")
(define-constant STATUS_EXPIRED "expired")

;; Authorization check
(define-private (is-authorized)
  (is-eq tx-sender (var-get contract-owner)))

;; Public functions
(define-public (grant-privilege
                (id (string-ascii 32))
                (provider-id (string-ascii 32))
                (hospital-id (string-ascii 32))
                (procedure-code (string-ascii 16))
                (granted-date (string-ascii 10))
                (expiration-date (string-ascii 10)))
  (begin
    (asserts! (is-authorized) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? privileges { id: id })) (err ERR_ALREADY_EXISTS))

    (map-set privileges
      { id: id }
      {
        provider-id: provider-id,
        hospital-id: hospital-id,
        procedure-code: procedure-code,
        granted-date: granted-date,
        expiration-date: expiration-date,
        status: STATUS_ACTIVE,
        approved-by: tx-sender,
        created-at: block-height,
        updated-at: block-height
      }
    )
    (ok id)
  )
)

(define-public (update-privilege-status
                (id (string-ascii 32))
                (status (string-ascii 16)))
  (let ((privilege (unwrap! (map-get? privileges { id: id }) (err ERR_NOT_FOUND))))
    (begin
      (asserts! (is-authorized) (err ERR_UNAUTHORIZED))
      (asserts! (or
                  (is-eq status STATUS_ACTIVE)
                  (is-eq status STATUS_PENDING)
                  (is-eq status STATUS_SUSPENDED)
                  (is-eq status STATUS_REVOKED)
                  (is-eq status STATUS_EXPIRED))
                (err ERR_INVALID_INPUT))

      (map-set privileges
        { id: id }
        (merge privilege
          {
            status: status,
            updated-at: block-height
          }
        )
      )
      (ok id)
    )
  )
)

(define-public (update-privilege-expiration
                (id (string-ascii 32))
                (expiration-date (string-ascii 10)))
  (let ((privilege (unwrap! (map-get? privileges { id: id }) (err ERR_NOT_FOUND))))
    (begin
      (asserts! (is-authorized) (err ERR_UNAUTHORIZED))

      (map-set privileges
        { id: id }
        (merge privilege
          {
            expiration-date: expiration-date,
            updated-at: block-height
          }
        )
      )
      (ok id)
    )
  )
)

(define-read-only (get-privilege (id (string-ascii 32)))
  (ok (map-get? privileges { id: id })))

