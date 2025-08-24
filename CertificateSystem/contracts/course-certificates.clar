(define-non-fungible-token course-certificate uint)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-certificate-exists (err u102))
(define-constant err-certificate-not-found (err u103))
(define-constant err-invalid-data (err u104))
(define-constant err-course-not-found (err u105))

;; Data Variables
(define-data-var next-certificate-id uint u1)
(define-data-var next-course-id uint u1)
(define-data-var total-certificates uint u0)

;; Maps
(define-map authorized-issuers principal bool)
(define-map courses 
  uint 
  {
    name: (string-ascii 64),
    institution: (string-ascii 64),
    duration-hours: uint,
    created-by: principal,
    active: bool
  })

(define-map certificates
  uint
  {
    course-id: uint,
    student: principal,
    issue-date: uint,
    completion-date: uint,
    grade: (string-ascii 2),
    issuer: principal,
    ipfs-hash: (string-ascii 64)
  })

(define-map student-certificates principal (list 20 uint))
(define-map course-certificates uint (list 100 uint))

;; Public Functions

;; Initialize contract and set owner as authorized issuer
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set authorized-issuers contract-owner true)
    (ok true)))

;; Add authorized certificate issuer (only owner)
(define-public (add-issuer (issuer principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set authorized-issuers issuer true)
    (print {action: "issuer-added", issuer: issuer})
    (ok true)))

;; Remove authorized issuer (only owner)
(define-public (remove-issuer (issuer principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-delete authorized-issuers issuer)
    (print {action: "issuer-removed", issuer: issuer})
    (ok true)))

;; Create a new course (authorized issuers only)
(define-public (create-course (name (string-ascii 64)) (institution (string-ascii 64)) (duration-hours uint))
  (let ((course-id (var-get next-course-id)))
    (asserts! (is-authorized-issuer tx-sender) err-not-authorized)
    (asserts! (> (len name) u0) err-invalid-data)
    (asserts! (> (len institution) u0) err-invalid-data)
    (asserts! (> duration-hours u0) err-invalid-data)
    
    (map-set courses course-id {
      name: name,
      institution: institution,
      duration-hours: duration-hours,
      created-by: tx-sender,
      active: true
    })
    (var-set next-course-id (+ course-id u1))
    (print {action: "course-created", course-id: course-id, name: name, institution: institution})
    (ok course-id)))

;; Issue certificate (authorized issuers only)
(define-public (issue-certificate 
  (course-id uint) 
  (student principal) 
  (completion-date uint) 
  (grade (string-ascii 2))
  (ipfs-hash (string-ascii 64)))
  (let ((certificate-id (var-get next-certificate-id)))
    (asserts! (is-authorized-issuer tx-sender) err-not-authorized)
    (asserts! (is-some (map-get? courses course-id)) err-course-not-found)
    (asserts! (> (len grade) u0) err-invalid-data)
    (asserts! (> completion-date u0) err-invalid-data)
    
    ;; Mint NFT certificate
    (try! (nft-mint? course-certificate certificate-id student))
    
    ;; Store certificate data
    (map-set certificates certificate-id {
      course-id: course-id,
      student: student,
      issue-date: block-height,
      completion-date: completion-date,
      grade: grade,
      issuer: tx-sender,
      ipfs-hash: ipfs-hash
    })
    
    ;; Update tracking maps
    (map-set student-certificates student 
      (unwrap-panic (as-max-len? 
        (append (get-student-certificates student) certificate-id) u20)))
    (map-set course-certificates course-id
      (unwrap-panic (as-max-len? 
        (append (get-course-certificates course-id) certificate-id) u100)))
    
    (var-set next-certificate-id (+ certificate-id u1))
    (var-set total-certificates (+ (var-get total-certificates) u1))
    
    (print {action: "certificate-issued", certificate-id: certificate-id, student: student, course-id: course-id})
    (ok certificate-id)))

;; Transfer certificate ownership
(define-public (transfer-certificate (certificate-id uint) (recipient principal))
  (let ((certificate (unwrap! (map-get? certificates certificate-id) err-certificate-not-found)))
    (try! (nft-transfer? course-certificate certificate-id tx-sender recipient))
    (print {action: "certificate-transferred", certificate-id: certificate-id, from: tx-sender, to: recipient})
    (ok true)))

;; Revoke certificate (issuer only)
(define-public (revoke-certificate (certificate-id uint))
  (let ((certificate (unwrap! (map-get? certificates certificate-id) err-certificate-not-found)))
    (asserts! (is-eq tx-sender (get issuer certificate)) err-not-authorized)
    (try! (nft-burn? course-certificate certificate-id (get student certificate)))
    (map-delete certificates certificate-id)
    (print {action: "certificate-revoked", certificate-id: certificate-id})
    (ok true)))

;; Read-only Functions

;; Check if principal is authorized issuer
(define-read-only (is-authorized-issuer (issuer principal))
  (default-to false (map-get? authorized-issuers issuer)))

;; Get course details
(define-read-only (get-course (course-id uint))
  (map-get? courses course-id))

;; Get certificate details
(define-read-only (get-certificate (certificate-id uint))
  (map-get? certificates certificate-id))

;; Get certificates owned by student
(define-read-only (get-student-certificates (student principal))
  (default-to (list) (map-get? student-certificates student)))

;; Get all certificates for a course
(define-read-only (get-course-certificates (course-id uint))
  (default-to (list) (map-get? course-certificates course-id)))

;; Verify certificate authenticity
(define-read-only (verify-certificate (certificate-id uint))
  (let ((certificate (map-get? certificates certificate-id))
        (owner (nft-get-owner? course-certificate certificate-id)))
    (match certificate
      cert-data (match owner
        cert-owner {
          valid: true,
          error: none,
          certificate: (some cert-data),
          current-owner: (some cert-owner),
          verified-at: block-height
        }
        {
          valid: false, 
          error: (some "certificate-not-owned"),
          certificate: none,
          current-owner: none,
          verified-at: block-height
        })
      {
        valid: false, 
        error: (some "certificate-not-found"),
        certificate: none,
        current-owner: none,
        verified-at: block-height
      })))

;; Get contract statistics
(define-read-only (get-stats)
  {
    total-certificates: (var-get total-certificates),
    next-certificate-id: (var-get next-certificate-id),
    next-course-id: (var-get next-course-id)
  })

;; Get certificate URI for metadata
(define-read-only (get-token-uri (certificate-id uint))
  (match (map-get? certificates certificate-id)
    certificate (ok (some (concat "https://ipfs.io/ipfs/" (get ipfs-hash certificate))))
    (ok none)))