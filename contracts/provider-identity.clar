;; provider-identity.clar
;; This contract manages healthcare practitioner identities

;; Define contract owner
(define-data-var contract-owner principal tx-sender)

;; Data structures
(define-map providers
  { id: (string-ascii 32) }
  {
    name: (string-ascii 64),
    specialty: (string-ascii 64),
    license-number: (string-ascii 32),
    npi: (string-ascii 10),
    active: bool,
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
(define-public (register-provider
                (id (string-ascii 32))
                (name (string-ascii 64))
                (specialty (string-ascii 64))
                (license-number (string-ascii 32))
                (npi (string-ascii 10)))
  (begin
    (asserts! (is-authorized) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? providers { id: id })) (err ERR_ALREADY_EXISTS))

    (map-set providers
      { id: id }
      {
        name: name,
        specialty: specialty,
        license-number: license-number,
        npi: npi,
        active: true,
        created-at: block-height,
        updated-at: block-height
      }
    )
    (ok id)
  )
)

(define-public (update-provider
                (id (string-ascii 32))
                (name (string-ascii 64))
                (specialty (string-ascii 64))
                (license-number (string-ascii 32))
                (npi (string-ascii 10))
                (active bool))
  (begin
    (asserts! (is-authorized) (err ERR_UNAUTHORIZED))
    (asserts! (is-some (map-get? providers { id: id })) (err ERR_NOT_FOUND))

    (map-set providers
      { id: id }
      {
        name: name,
        specialty: specialty,
        license-number: license-number,
        npi: npi,
        active: active,
        created-at: (get created-at (unwrap! (map-get? providers { id: id }) (err ERR_NOT_FOUND))),
        updated-at: block-height
      }
    )
    (ok id)
  )
)

(define-public (deactivate-provider (id (string-ascii 32)))
  (let ((provider (unwrap! (map-get? providers { id: id }) (err ERR_NOT_FOUND))))
    (begin
      (asserts! (is-authorized) (err ERR_UNAUTHORIZED))

      (map-set providers
        { id: id }
        (merge provider { active: false, updated-at: block-height })
      )
      (ok id)
    )
  )
)

(define-read-only (get-provider (id (string-ascii 32)))
  (ok (map-get? providers { id: id })))

