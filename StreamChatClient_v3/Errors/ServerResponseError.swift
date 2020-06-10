//
// ServerResponseError.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A parsed server response error.
struct ServerResponseError: LocalizedError, Decodable, CustomDebugStringConvertible, Error {
  /// The error codes for token-related errors. Typically, a refreshed token is required to recover.
  static let tokenInvadlidErrorCodes = 40 ... 43

  private enum CodingKeys: String, CodingKey {
    case code
    case message
    case statusCode = "StatusCode"
  }

  /// An error code.
  public let code: Int
  /// A message.
  public let message: String
  /// A status code.
  public let statusCode: Int

  public var errorDescription: String? {
    "Error #\(code): \(message)"
  }

  public var debugDescription: String {
    "ClientErrorResponse(code: \(code), message: \"\(message)\", statusCode: \(statusCode)))."
  }
}
