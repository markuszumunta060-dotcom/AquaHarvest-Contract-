(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-insufficient-funds (err u105))
(define-constant err-insufficient-water (err u106))
(define-constant err-system-inactive (err u107))

(define-data-var well-id-nonce uint u1)
(define-data-var distribution-id-nonce uint u1)
(define-data-var maintenance-id-nonce uint u1)
(define-data-var total-water-harvested uint u0)
(define-data-var total-water-distributed uint u0)
(define-data-var emergency-mode bool false)

(define-map community-members principal
  {
    name: (string-ascii 50),
    location: (string-ascii 100),
    role: (string-ascii 30),
    contribution-points: uint,
    water-allocation: uint,
    registered-at: uint,
    active: bool
  })

(define-map water-wells uint
  {
    name: (string-ascii 100),
    location: (string-ascii 150),
    owner: principal,
    capacity-liters: uint,
    current-level: uint,
    water-quality: uint,
    installation-cost: uint,
    operational: bool,
    last-maintenance: uint,
    created-at: uint
  })

(define-map water-distributions uint
  {
    well-id: uint,
    recipient: principal,
    amount-liters: uint,
    distribution-type: (string-ascii 30),
    cost: uint,
    timestamp: uint,
    emergency: bool
  })

(define-map maintenance-records uint
  {
    well-id: uint,
    maintainer: principal,
    maintenance-type: (string-ascii 50),
    cost: uint,
    description: (string-ascii 200),
    completed: bool,
    scheduled-at: uint,
    completed-at: (optional uint)
  })

(define-map harvesting-cycles {well-id: uint, cycle: uint}
  {
    start-level: uint,
    end-level: uint,
    rainfall-mm: uint,
    harvest-efficiency: uint,
    start-date: uint,
    end-date: (optional uint)
  })

(define-map water-quality-tests {well-id: uint, test-date: uint}
  {
    ph-level: uint,
    bacteria-count: uint,
    chemical-contamination: uint,
    potability-score: uint,
    tester: principal,
    certified: bool
  })

(define-map community-contributions {member: principal, contribution-type: (string-ascii 30)}
  {
    amount: uint,
    description: (string-ascii 150),
    reward-points: uint,
    contributed-at: uint
  })

(define-public (register-member (name (string-ascii 50)) (location (string-ascii 100)) (role (string-ascii 30)))
  (let ((caller tx-sender))
    (asserts! (is-none (map-get? community-members caller)) err-already-exists)
    (ok (map-set community-members caller {
      name: name,
      location: location,
      role: role,
      contribution-points: u0,
      water-allocation: u1000,
      registered-at: stacks-block-height,
      active: true
    }))))

(define-public (install-well 
  (name (string-ascii 100)) 
  (location (string-ascii 150)) 
  (capacity-liters uint) 
  (installation-cost uint))
  (let (
    (well-id (var-get well-id-nonce))
    (caller tx-sender)
  )
    (asserts! (is-some (map-get? community-members caller)) err-unauthorized)
    (asserts! (> capacity-liters u0) err-invalid-input)
    (try! (stx-transfer? installation-cost caller (as-contract tx-sender)))
    (map-set water-wells well-id {
      name: name,
      location: location,
      owner: caller,
      capacity-liters: capacity-liters,
      current-level: u0,
      water-quality: u50,
      installation-cost: installation-cost,
      operational: true,
      last-maintenance: stacks-block-height,
      created-at: stacks-block-height
    })
    (let ((member (unwrap-panic (map-get? community-members caller))))
      (map-set community-members caller (merge member {
        contribution-points: (+ (get contribution-points member) u50)
      })))
    (var-set well-id-nonce (+ well-id u1))
    (ok well-id)))

(define-public (harvest-rainwater (well-id uint) (rainfall-mm uint) (harvest-efficiency uint))
  (let (
    (well (unwrap! (map-get? water-wells well-id) err-not-found))
    (caller tx-sender)
    (harvested-amount (/ (* rainfall-mm harvest-efficiency) u100))
  )
    (asserts! (is-eq caller (get owner well)) err-unauthorized)
    (asserts! (get operational well) err-system-inactive)
    (asserts! (<= harvest-efficiency u100) err-invalid-input)
    (let ((new-level (+ (get current-level well) harvested-amount)))
      (map-set water-wells well-id (merge well {
        current-level: (if (> new-level (get capacity-liters well))
          (get capacity-liters well)
          new-level)
      }))
      (var-set total-water-harvested (+ (var-get total-water-harvested) harvested-amount))
      (map-set harvesting-cycles {well-id: well-id, cycle: stacks-block-height} {
        start-level: (get current-level well),
        end-level: new-level,
        rainfall-mm: rainfall-mm,
        harvest-efficiency: harvest-efficiency,
        start-date: stacks-block-height,
        end-date: (some stacks-block-height)
      }))
    (ok harvested-amount)))

(define-public (distribute-water (well-id uint) (recipient principal) (amount-liters uint) (distribution-type (string-ascii 30)))
  (let (
    (well (unwrap! (map-get? water-wells well-id) err-not-found))
    (member (unwrap! (map-get? community-members recipient) err-not-found))
    (caller tx-sender)
    (is-emergency (var-get emergency-mode))
    (cost (if is-emergency u0 (* amount-liters u10)))
  )
    (asserts! (or (is-eq caller (get owner well)) (is-eq caller contract-owner)) err-unauthorized)
    (asserts! (get operational well) err-system-inactive)
    (asserts! (get active member) err-unauthorized)
    (asserts! (>= (get current-level well) amount-liters) err-insufficient-water)
    (asserts! (or is-emergency (>= (get water-allocation member) amount-liters)) err-insufficient-funds)
    (if (not is-emergency)
      (try! (stx-transfer? cost recipient (as-contract tx-sender)))
      true)
    (let ((distribution-id (var-get distribution-id-nonce)))
      (map-set water-distributions distribution-id {
        well-id: well-id,
        recipient: recipient,
        amount-liters: amount-liters,
        distribution-type: distribution-type,
        cost: cost,
        timestamp: stacks-block-height,
        emergency: is-emergency
      })
      (map-set water-wells well-id (merge well {
        current-level: (- (get current-level well) amount-liters)
      }))
      (if (not is-emergency)
        (map-set community-members recipient (merge member {
          water-allocation: (- (get water-allocation member) amount-liters)
        }))
        true)
      (var-set distribution-id-nonce (+ distribution-id u1))
      (var-set total-water-distributed (+ (var-get total-water-distributed) amount-liters)))
    (ok true)))

(define-public (test-water-quality (well-id uint) (ph-level uint) (bacteria-count uint) (chemical-contamination uint))
  (let (
    (well (unwrap! (map-get? water-wells well-id) err-not-found))
    (caller tx-sender)
    (potability-score (calculate-potability ph-level bacteria-count chemical-contamination))
  )
    (asserts! (is-some (map-get? community-members caller)) err-unauthorized)
    (map-set water-quality-tests {well-id: well-id, test-date: stacks-block-height} {
      ph-level: ph-level,
      bacteria-count: bacteria-count,
      chemical-contamination: chemical-contamination,
      potability-score: potability-score,
      tester: caller,
      certified: (> potability-score u75)
    })
    (map-set water-wells well-id (merge well {
      water-quality: potability-score
    }))
    (let ((member (unwrap-panic (map-get? community-members caller))))
      (map-set community-members caller (merge member {
        contribution-points: (+ (get contribution-points member) u25)
      })))
    (ok potability-score)))

(define-public (schedule-maintenance (well-id uint) (maintenance-type (string-ascii 50)) (description (string-ascii 200)) (cost uint))
  (let (
    (well (unwrap! (map-get? water-wells well-id) err-not-found))
    (caller tx-sender)
    (maintenance-id (var-get maintenance-id-nonce))
  )
    (asserts! (or (is-eq caller (get owner well)) (is-eq caller contract-owner)) err-unauthorized)
    (map-set maintenance-records maintenance-id {
      well-id: well-id,
      maintainer: caller,
      maintenance-type: maintenance-type,
      cost: cost,
      description: description,
      completed: false,
      scheduled-at: stacks-block-height,
      completed-at: none
    })
    (var-set maintenance-id-nonce (+ maintenance-id u1))
    (ok maintenance-id)))

(define-public (complete-maintenance (maintenance-id uint))
  (let (
    (maintenance (unwrap! (map-get? maintenance-records maintenance-id) err-not-found))
    (well (unwrap! (map-get? water-wells (get well-id maintenance)) err-not-found))
    (caller tx-sender)
  )
    (asserts! (is-eq caller (get maintainer maintenance)) err-unauthorized)
    (asserts! (not (get completed maintenance)) err-invalid-input)
    (try! (stx-transfer? (get cost maintenance) caller (as-contract tx-sender)))
    (map-set maintenance-records maintenance-id (merge maintenance {
      completed: true,
      completed-at: (some stacks-block-height)
    }))
    (map-set water-wells (get well-id maintenance) (merge well {
      last-maintenance: stacks-block-height
    }))
    (let ((member (unwrap-panic (map-get? community-members caller))))
      (map-set community-members caller (merge member {
        contribution-points: (+ (get contribution-points member) u30)
      })))
    (ok true)))

(define-public (contribute-to-community (contribution-type (string-ascii 30)) (amount uint) (description (string-ascii 150)))
  (let ((caller tx-sender))
    (asserts! (is-some (map-get? community-members caller)) err-unauthorized)
    (asserts! (> amount u0) err-invalid-input)
    (try! (stx-transfer? amount caller (as-contract tx-sender)))
    (let ((reward-points (/ amount u100)))
      (map-set community-contributions {member: caller, contribution-type: contribution-type} {
        amount: amount,
        description: description,
        reward-points: reward-points,
        contributed-at: stacks-block-height
      })
      (let ((member (unwrap-panic (map-get? community-members caller))))
        (map-set community-members caller (merge member {
          contribution-points: (+ (get contribution-points member) reward-points),
          water-allocation: (+ (get water-allocation member) (/ amount u50))
        }))))
    (ok true)))

(define-public (toggle-emergency-mode)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set emergency-mode (not (var-get emergency-mode)))
    (ok (var-get emergency-mode))))

(define-public (deactivate-well (well-id uint))
  (let ((well (unwrap! (map-get? water-wells well-id) err-not-found)))
    (asserts! (or (is-eq tx-sender (get owner well)) (is-eq tx-sender contract-owner)) err-unauthorized)
    (map-set water-wells well-id (merge well {operational: false}))
    (ok true)))

(define-public (update-water-allocation (member principal) (new-allocation uint))
  (let ((member-data (unwrap! (map-get? community-members member) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set community-members member (merge member-data {water-allocation: new-allocation}))
    (ok true)))

(define-read-only (get-member (member principal))
  (map-get? community-members member))

(define-read-only (get-well (well-id uint))
  (map-get? water-wells well-id))

(define-read-only (get-distribution (distribution-id uint))
  (map-get? water-distributions distribution-id))

(define-read-only (get-maintenance-record (maintenance-id uint))
  (map-get? maintenance-records maintenance-id))

(define-read-only (get-harvesting-cycle (well-id uint) (cycle uint))
  (map-get? harvesting-cycles {well-id: well-id, cycle: cycle}))

(define-read-only (get-water-quality-test (well-id uint) (test-date uint))
  (map-get? water-quality-tests {well-id: well-id, test-date: test-date}))

(define-read-only (get-community-contribution (member principal) (contribution-type (string-ascii 30)))
  (map-get? community-contributions {member: member, contribution-type: contribution-type}))

(define-read-only (get-system-stats)
  {
    total-wells: (- (var-get well-id-nonce) u1),
    total-distributions: (- (var-get distribution-id-nonce) u1),
    total-maintenance-records: (- (var-get maintenance-id-nonce) u1),
    total-water-harvested: (var-get total-water-harvested),
    total-water-distributed: (var-get total-water-distributed),
    emergency-mode: (var-get emergency-mode),
    contract-owner: contract-owner
  })

(define-read-only (calculate-well-efficiency (well-id uint))
  (match (map-get? water-wells well-id)
    well (let (
      (utilization-rate (if (> (get capacity-liters well) u0)
        (/ (* (get current-level well) u100) (get capacity-liters well))
        u0))
    )
    (some {
      capacity-liters: (get capacity-liters well),
      current-level: (get current-level well),
      utilization-rate: utilization-rate,
      quality-score: (get water-quality well),
      efficiency-rating: (/ (+ utilization-rate (get water-quality well)) u2)
    }))
    none))

(define-private (calculate-potability (ph uint) (bacteria uint) (chemicals uint))
  (let (
    (ph-score (if (and (>= ph u65) (<= ph u85)) u100 u50))
    (bacteria-score (if (<= bacteria u10) u100 (- u100 bacteria)))
    (chemical-score (if (<= chemicals u5) u100 (- u100 (* chemicals u10))))
  )
  (/ (+ ph-score bacteria-score chemical-score) u3)))