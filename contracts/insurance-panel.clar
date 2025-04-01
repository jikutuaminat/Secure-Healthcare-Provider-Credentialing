;; insurance-panel.clar
;; This contract manages participation in insurance networks

;; Define contract owner
(define-data-var contract-owner principal tx-sender)

;; Data structures
(define-map panel-memberships
  { id: (string-ascii 32) }
  {
    provider-id: (string-ascii 32),
    insurance-id: (string-ascii 32),
    panel-type: (string-ascii 32),
    effective-date: (string-ascii 10),
    termination-date: (string-ascii 10),
    status: (string-ascii 16),
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
(define-constant STATUS_TERMINATED "terminated")

;; Authorization check
(define-private (is-authorized)
  (is-eq tx-sender (var-get contract-owner)))

;; Public functions
(define-public (add-to-panel
                (id (string-ascii 32))
                (provider-id (string-ascii 32))
                (insurance-id (string-ascii 32))
                (panel-type (string-ascii 32))
                (effective-date (string-ascii 10))
                (termination-date (string-ascii 10)))
  (begin
    (asserts! (is-authorized) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? panel-memberships { id: id })) (err ERR_ALREADY_EXISTS))

    (map-set panel-memberships
      { id: id }
      {
        provider-id: provider-id,
        insurance-id: insurance-id,
        panel-type: panel-type,
        effective-date: effective-date,
        termination-date: termination-date,
        status: STATUS_ACTIVE,
        created-at: block-height,
        updated-at: block-height
      }
    )
    (ok id)
  )
)

(define-public (update-panel-status
                (id (string-ascii 32))
                (status (string-ascii 16)))
  (let ((membership (unwrap! (map-get? panel-memberships { id: id }) (err ERR_NOT_FOUND))))
    (begin
      (asserts! (is-authorized) (err ERR_UNAUTHORIZED))
      (asserts! (or
                  (is-eq status STATUS_ACTIVE)
                  (is-eq status STATUS_PENDING)
                  (is-eq status STATUS_TERMINATED))
                (err ERR_INVALID_INPUT))

      (map-set panel-memberships
        { id: id }
        (merge membership
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

(define-public (terminate-panel-membership
                (id (string-ascii 32))
                (termination-date (string-ascii 10)))
  (let ((membership (unwrap! (map-get? panel-memberships { id: id }) (err ERR_NOT_FOUND))))
    (begin
      (asserts! (is-authorized) (err ERR_UNAUTHORIZED))

      (map-set panel-memberships
        { id: id }
        (merge membership
          {
            termination-date: termination-date,
            status: STATUS_TERMINATED,
            updated-at: block-height
          }
        )
      )
      (ok id)
    )
  )
)

(define-read-only (get-panel-membership (id (string-ascii 32)))
  (ok (map-get? panel-memberships { id: id })))

