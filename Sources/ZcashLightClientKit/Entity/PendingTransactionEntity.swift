//
//  PendingTransactionEntity.swift
//  ZcashLightClientKit
//
//  Created by Francisco Gindre on 11/19/19.
//

import Foundation

public enum PendingTransactionRecipient: Equatable {
    case address(Recipient)
    case internalAccount(UInt32)
}

/**
Represents a sent transaction that has not been confirmed yet on the blockchain
*/
public protocol PendingTransactionEntity: RawIdentifiable {
    /**
    internal id for this transaction
    */
    var id: Int? { get set }

    /**
    value in zatoshi
    */
    var value: Zatoshi { get set }

    /**
    data containing the memo if any
    */
    var memo: Data? { get set }

    var fee: Zatoshi? { get set }

    var raw: Data? { get set }

    /**
    recipient address
    */
    var recipient: PendingTransactionRecipient { get }

    /**
    index of the account from which the funds were sent
    */
    var accountIndex: Int { get }
    
    /**
    height which the block was mined at.
    -1 when block has not been mined yet
    */
    var minedHeight: BlockHeight { get set }

    /**
    height for which the represented transaction would be considered expired
    */
    var expiryHeight: BlockHeight { get set }

    /**
    value is 1 if the transaction was cancelled
    */
    var cancelled: Int { get }

    /**
    how many times this transaction encoding was attempted
    */
    var encodeAttempts: Int { get set }
    
    /**
    How many attempts to send this transaction have been done
    */
    var submitAttempts: Int { get set }

    /**
    Error message if available.
    */
    var errorMessage: String? { get set }

    /**
    error code, if available
    */
    var errorCode: Int? { get set }

    /**
    create time of the represented transaction
     
    - Note: represented in timeIntervalySince1970
    */
    var createTime: TimeInterval { get }
    
    /**
    Checks whether this transaction is the same as the given transaction
    */
    func isSameTransactionId<T: RawIdentifiable> (other: T) -> Bool
    
    /**
    returns whether the represented transaction is pending based on the provided block height
    */
    func isPending(currentHeight: Int) -> Bool
    
    /**
    if the represented transaction is being created
    */
    var isCreating: Bool { get }
    
    /**
    returns whether the represented transaction has failed to be encoded
    */
    var isFailedEncoding: Bool { get }

    /**
    returns whether the represented transaction has failed to be submitted
    */
    var isFailedSubmit: Bool { get }
    
    /**
    returns whether the represented transaction presents some kind of error
    */
    var isFailure: Bool { get }

    /**
    returns whether the represented transaction has been cancelled by the user
    */
    var isCancelled: Bool { get }

    /**
    returns whether the represented transaction has been successfully mined
    */
    var isMined: Bool { get }

    /**
    returns whether the represented transaction has been submitted
    */
    var isSubmitted: Bool { get }
    
    /**
    returns whether the represented transaction has been submitted successfully
    */
    var isSubmitSuccess: Bool { get }
}

public extension PendingTransactionEntity {
    func isSameTransaction<T: RawIdentifiable>(other: T) -> Bool {
        guard let selfId = self.rawTransactionId, let otherId = other.rawTransactionId else { return false }
        return selfId == otherId
    }
    
    var isCreating: Bool {
        (raw?.isEmpty ?? true) != false && submitAttempts <= 0 && !isFailedSubmit && !isFailedEncoding
    }
    
    var isFailedEncoding: Bool {
        (raw?.isEmpty ?? true) != false && encodeAttempts > 0
    }
    
    var isFailedSubmit: Bool {
        errorMessage != nil || (errorCode != nil && (errorCode ?? 0) < 0)
    }
    
    var isFailure: Bool {
        isFailedEncoding || isFailedSubmit
    }
    
    var isCancelled: Bool {
        cancelled > 0
    }
    
    var isMined: Bool {
        minedHeight > 0
    }
    
    var isSubmitted: Bool {
        submitAttempts > 0
    }
    
    func isPending(currentHeight: Int = -1) -> Bool {
        // not mined and not expired and successfully created
        isSubmitSuccess && !isConfirmed(currentHeight: currentHeight) && (expiryHeight == -1 || expiryHeight > currentHeight) && raw != nil
    }
        
    var isSubmitSuccess: Bool {
        submitAttempts > 0 && (errorCode == nil || (errorCode ?? 0) >= 0) && errorMessage == nil
    }
    
    func isConfirmed(currentHeight: Int = -1 ) -> Bool {
        guard minedHeight > 0 else {
            return false
        }
        
        guard currentHeight > 0 else {
            return false
        }
        
        return abs(currentHeight - minedHeight) >= ZcashSDK.defaultStaleTolerance
    }
}

public extension PendingTransactionEntity {
    func makeTransactionEntity(defaultFee: Zatoshi) -> ZcashTransaction.Overview {
        return ZcashTransaction.Overview(
            blockTime: createTime,
            expiryHeight: expiryHeight,
            fee: fee,
            id: id ?? -1,
            index: nil,
            isWalletInternal: false,
            hasChange: false,
            memoCount: 0,
            minedHeight: minedHeight,
            raw: raw,
            rawID: rawTransactionId ?? Data(),
            receivedNoteCount: 0,
            sentNoteCount: 0,
            value: value
        )
    }
}
