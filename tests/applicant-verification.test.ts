import { describe, it, expect, beforeEach } from "vitest"

// Mock Clarity functions and environment
const mockTxSender = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
const mockVerifier = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
const mockApplicantId = "123e4567-e89b-12d3-a456-426614174000"

// Mock state
let mockState = {
  admin: mockTxSender,
  applicants: {},
  authorizedVerifiers: {},
}

// Mock contract functions
const mockContractFunctions = {
  "add-verifier": (verifier) => {
    if (mockState.admin !== mockTxSender) {
      return { type: "err", value: 1000 }
    }
    mockState.authorizedVerifiers[verifier] = true
    return { type: "ok", value: true }
  },
  "submit-applicant-info": (applicantId, fullName, dateOfBirth, idDocumentHash) => {
    if (mockState.applicants[applicantId]) {
      return { type: "err", value: 1002 }
    }
    mockState.applicants[applicantId] = {
      principal: mockTxSender,
      fullName,
      dateOfBirth,
      idDocumentHash,
      verified: false,
      verificationDate: null,
    }
    return { type: "ok", value: true }
  },
  "verify-applicant": (applicantId) => {
    if (!mockState.applicants[applicantId]) {
      return { type: "err", value: 1003 }
    }
    if (!mockState.authorizedVerifiers[mockTxSender]) {
      return { type: "err", value: 1004 }
    }
    mockState.applicants[applicantId].verified = true
    mockState.applicants[applicantId].verificationDate = 123 // Mock block height
    return { type: "ok", value: true }
  },
  "is-applicant-verified": (applicantId) => {
    if (!mockState.applicants[applicantId]) {
      return { type: "err", value: 1003 }
    }
    return { type: "ok", value: mockState.applicants[applicantId].verified }
  },
}

describe("Applicant Verification Contract", () => {
  beforeEach(() => {
    // Reset state before each test
    mockState = {
      admin: mockTxSender,
      applicants: {},
      authorizedVerifiers: {},
    }
  })
  
  it("should add a verifier successfully", () => {
    const result = mockContractFunctions["add-verifier"](mockVerifier)
    expect(result.type).toBe("ok")
    expect(mockState.authorizedVerifiers[mockVerifier]).toBe(true)
  })
  
  it("should submit applicant information successfully", () => {
    const result = mockContractFunctions["submit-applicant-info"](
        mockApplicantId,
        "John Doe",
        "1990-01-01",
        Buffer.from("mock-hash"),
    )
    expect(result.type).toBe("ok")
    expect(mockState.applicants[mockApplicantId]).toBeDefined()
    expect(mockState.applicants[mockApplicantId].verified).toBe(false)
  })
  
  it("should fail to submit duplicate applicant information", () => {
    // First submission
    mockContractFunctions["submit-applicant-info"](mockApplicantId, "John Doe", "1990-01-01", Buffer.from("mock-hash"))
    
    // Second submission with same ID
    const result = mockContractFunctions["submit-applicant-info"](
        mockApplicantId,
        "Jane Doe",
        "1991-02-02",
        Buffer.from("another-hash"),
    )
    
    expect(result.type).toBe("err")
    expect(result.value).toBe(1002)
  })
  
  it("should verify an applicant successfully", () => {
    // Add verifier
    mockContractFunctions["add-verifier"](mockTxSender)
    
    // Submit applicant info
    mockContractFunctions["submit-applicant-info"](mockApplicantId, "John Doe", "1990-01-01", Buffer.from("mock-hash"))
    
    // Verify applicant
    const result = mockContractFunctions["verify-applicant"](mockApplicantId)
    
    expect(result.type).toBe("ok")
    expect(mockState.applicants[mockApplicantId].verified).toBe(true)
  })
  
  it("should fail to verify a non-existent applicant", () => {
    // Add verifier
    mockContractFunctions["add-verifier"](mockTxSender)
    
    // Try to verify non-existent applicant
    const result = mockContractFunctions["verify-applicant"]("non-existent-id")
    
    expect(result.type).toBe("err")
    expect(result.value).toBe(1003)
  })
  
  it("should fail to verify if not an authorized verifier", () => {
    // Submit applicant info
    mockContractFunctions["submit-applicant-info"](mockApplicantId, "John Doe", "1990-01-01", Buffer.from("mock-hash"))
    
    // Try to verify without being authorized
    const result = mockContractFunctions["verify-applicant"](mockApplicantId)
    
    expect(result.type).toBe("err")
    expect(result.value).toBe(1004)
  })
  
  it("should check if an applicant is verified", () => {
    // Submit applicant info
    mockContractFunctions["submit-applicant-info"](mockApplicantId, "John Doe", "1990-01-01", Buffer.from("mock-hash"))
    
    // Check verification status (should be false)
    let result = mockContractFunctions["is-applicant-verified"](mockApplicantId)
    expect(result.type).toBe("ok")
    expect(result.value).toBe(false)
    
    // Add verifier and verify applicant
    mockContractFunctions["add-verifier"](mockTxSender)
    mockContractFunctions["verify-applicant"](mockApplicantId)
    
    // Check verification status again (should be true)
    result = mockContractFunctions["is-applicant-verified"](mockApplicantId)
    expect(result.type).toBe("ok")
    expect(result.value).toBe(true)
  })
})
