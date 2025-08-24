# 🎓 EduChain Certificate System

A Stacks blockchain smart contract for issuing, managing, and verifying educational course certificates as NFTs.

## 📋 Overview

The Course Certificates contract enables educational institutions to issue tamper-proof, verifiable certificates on the Stacks blockchain. Each certificate is minted as a unique NFT, ensuring authenticity and preventing fraud.

## ✨ Features

- **Course Management**: Create and manage educational courses
- **NFT Certificates**: Issue certificates as transferable NFTs
- **Access Control**: Authorize trusted certificate issuers
- **Verification System**: On-chain certificate authenticity verification
- **IPFS Integration**: Store rich metadata off-chain
- **Transfer Support**: Students can transfer certificates between wallets
- **Revocation**: Issuers can revoke invalid certificates

## 🚀 Quick Start

### Deploy Contract
```bash
clarinet check
clarinet test
clarinet deploy
```

### Key Functions

#### For Administrators
- `initialize()` - Set up the contract
- `add-issuer(principal)` - Authorize certificate issuers
- `remove-issuer(principal)` - Revoke issuer permissions

#### For Educational Institutions
- `create-course(name, institution, duration)` - Register a new course
- `issue-certificate(course-id, student, completion-date, grade, ipfs-hash)` - Issue certificate to student
- `revoke-certificate(certificate-id)` - Revoke invalid certificates

#### For Students & Public
- `transfer-certificate(certificate-id, recipient)` - Transfer certificate ownership
- `verify-certificate(certificate-id)` - Verify certificate authenticity
- `get-student-certificates(student)` - Get all certificates for a student

## 📊 Data Structure

### Course
```clarity
{
  name: string-ascii,
  institution: string-ascii,
  duration-hours: uint,
  created-by: principal,
  active: bool
}
```

### Certificate
```clarity
{
  course-id: uint,
  student: principal,
  issue-date: uint,
  completion-date: uint,
  grade: string-ascii,
  issuer: principal,
  ipfs-hash: string-ascii
}
```

## 🔒 Security Features

- **Multi-signature authorization** for certificate issuers
- **Input validation** on all public functions
- **Ownership verification** for transfers and revocations
- **Immutable records** once issued (unless revoked by issuer)

## 🎯 Use Cases

- **Universities**: Degree and diploma certificates
- **Bootcamps**: Technical skill certifications
- **Corporate Training**: Professional development credentials
- **Online Courses**: MOOC completion certificates
- **Professional Bodies**: Industry certifications

## 🧪 Testing

```bash
# Run all tests
clarinet test

# Check contract syntax
clarinet check

# Run specific test
clarinet test tests/certificate-tests.ts
```

## 📚 Example Usage

```clarity
;; 1. Initialize contract (owner only)
(contract-call? .course-certificates initialize)

;; 2. Add authorized issuer
(contract-call? .course-certificates add-issuer 'SP1ABC...)

;; 3. Create a course
(contract-call? .course-certificates create-course 
  "Blockchain Development" "Tech University" u160)

;; 4. Issue certificate
(contract-call? .course-certificates issue-certificate 
  u1 'SP1STUDENT... u1234567 "A+" "QmXyz123...")

;; 5. Verify certificate
(contract-call? .course-certificates verify-certificate u1)
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Add tests for new functionality
4. Ensure `clarinet check` passes
5. Submit a pull request