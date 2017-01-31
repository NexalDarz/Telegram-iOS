import Foundation

enum UpdateGroup: CustomStringConvertible {
    case withPts(updates: [Api.Update], users: [Api.User], chats: [Api.Chat])
    case withQts(updates: [Api.Update], users: [Api.User], chats: [Api.Chat])
    case withSeq(updates: [Api.Update], seqRange: (Int32, Int32), date: Int32, users: [Api.User], chats: [Api.Chat])
    case withDate(updates: [Api.Update], date: Int32, users: [Api.User], chats: [Api.Chat])
    case reset
    case updatePts(pts: Int32, ptsCount: Int32)
    
    var updates: [Api.Update] {
        switch self {
            case let .withPts(updates, _, _):
                return updates
            case let .withDate(updates, _, _, _):
                return updates
            case let .withQts(updates, _, _):
                return updates
            case let .withSeq(updates, _, _, _, _):
                return updates
            case .reset, .updatePts:
                return []
        }
    }
    
    var users: [Api.User] {
        switch self {
            case let .withPts(_, users, _):
                return users
            case let .withDate(_, _, users, _):
                return users
            case let .withQts(_, users, _):
                return users
            case let .withSeq(_, _, _, users, _):
                return users
            case .reset, .updatePts:
                return []
        }
    }
    
    var chats: [Api.Chat] {
        switch self {
            case let .withPts(_, _, chats):
                return chats
            case let .withDate(_, _, _, chats):
                return chats
            case let .withQts(_, _, chats):
                return chats
            case let .withSeq(_, _, _, _, chats):
                return chats
            case .reset, .updatePts:
                return []
        }
    }
    
    var description: String {
        var string = ""
        
        switch self {
        case let .withPts(updates, _, _):
            string += "withPts("
            var first = true
            for update in updates {
                if first {
                    first = false
                } else {
                    string += ", "
                }
                string += "\(update)"
            }
            string += ")"
        case let .withQts(updates, _, _):
            string += "withQts("
            var first = true
            for update in updates {
                if first {
                    first = false
                } else {
                    string += ", "
                }
                string += "\(update)"
            }
            string += ")"
        case let .withSeq(updates, seqRange, date, _, _):
            string += "withSeq(seq \(seqRange.0)..\(seqRange.1), date \(date), "
            var first = true
            for update in updates {
                if first {
                    first = false
                } else {
                    string += ", "
                }
                string += "\(update)"
            }
            string += ")"
        case let .withDate(updates, date, _, _):
            string += "withDate(date \(date), "
            var first = true
            for update in updates {
                if first {
                    first = false
                } else {
                    string += ", "
                }
                string += "\(update)"
            }
            string += ")"
        case .reset:
            string += "reset"
        case .updatePts:
            string += "updatePts"
        }
        
        return string
    }
}

extension Api.Update {
    var ptsRange: (Int32, Int32)? {
        get {
            switch self {
                case let .updateDeleteMessages(_, pts, ptsCount):
                    return (pts, ptsCount)
                case let .updateNewMessage(_, pts, ptsCount):
                    return (pts, ptsCount)
                case let .updateReadHistoryInbox(_, _, pts, ptsCount):
                    return (pts, ptsCount)
                case let .updateReadHistoryOutbox(_, _, pts, ptsCount):
                    return (pts, ptsCount)
                case let .updateEditMessage(_, pts, ptsCount):
                    return (pts, ptsCount)
                case let .updateReadMessagesContents(_, pts, ptsCount):
                    return (pts, ptsCount)
                case let .updateWebPage(_, pts, ptsCount):
                    return (pts, ptsCount)
                default:
                    return nil
            }
        }
    }
    
    var qtsRange: (Int32, Int32)? {
        get {
            switch self {
            case let .updateNewEncryptedMessage(_, qts):
                return (qts, 1)
            case _:
                return nil
            }
        }
    }
}

struct PtsUpdate {
    let update: Api.Update?
    let ptsRange: (Int32, Int32)
    let users: [Api.User]
    let chats: [Api.Chat]
}

struct QtsUpdate {
    let update: Api.Update
    let qtsRange: (Int32, Int32)
    let users: [Api.User]
    let chats: [Api.Chat]
}

struct SeqUpdates {
    let updates: [Api.Update]
    let seqRange: (Int32, Int32)
    let date: Int32
    let users: [Api.User]
    let chats: [Api.Chat]
}

func ptsUpdates(_ groups: [UpdateGroup]) -> [PtsUpdate] {
    var result: [PtsUpdate] = []
    
    for group in groups {
        switch group {
        case let .withPts(updates, users, chats):
            for update in updates {
                if let ptsRange = update.ptsRange {
                    result.append(PtsUpdate(update: update, ptsRange: ptsRange, users: users, chats: chats))
                }
            }
        case let .updatePts(pts, ptsCount):
                result.append(PtsUpdate(update: nil, ptsRange: (pts, ptsCount), users: [], chats: []))
        case _:
            break
        }
    }
    
    result.sort(by: { $0.ptsRange.0 < $1.ptsRange.0 })
    
    return result
}

func qtsUpdates(_ groups: [UpdateGroup]) -> [QtsUpdate] {
    var result: [QtsUpdate] = []
    
    for group in groups {
        switch group {
            case let .withQts(updates, users, chats):
                for update in updates {
                    if let qtsRange = update.qtsRange {
                        result.append(QtsUpdate(update: update, qtsRange: qtsRange, users: users, chats: chats))
                    }
                }
                break
            case _:
                break
        }
    }
    
    result.sort(by: { $0.qtsRange.0 < $1.qtsRange.0 })
    
    return result
}

func seqGroups(_ groups: [UpdateGroup]) -> [SeqUpdates] {
    var result: [SeqUpdates] = []
    
    for group in groups {
        switch group {
            case let .withSeq(updates, seqRange, date, users, chats):
                result.append(SeqUpdates(updates: updates, seqRange: seqRange, date: date, users: users, chats: chats))
            case _:
                break
        }
    }
    
    return result
}

func dateGroups(_ groups: [UpdateGroup]) -> [UpdateGroup] {
    var result: [UpdateGroup] = []
    
    for group in groups {
        switch group {
            case .withDate:
                result.append(group)
            case _:
                break
        }
    }
    
    return result
}

func groupUpdates(_ updates: [Api.Update], users: [Api.User], chats: [Api.Chat], date: Int32, seqRange: (Int32, Int32)?) -> [UpdateGroup] {
    var updatesWithPts: [Api.Update] = []
    var updatesWithQts: [Api.Update] = []
    var otherUpdates: [Api.Update] = []
    
    for update in updates {
        if let _ = update.ptsRange {
            updatesWithPts.append(update)
        } else if let _ = update.qtsRange {
            updatesWithQts.append(update)
        } else {
            otherUpdates.append(update)
        }
    }
    
    var groups: [UpdateGroup] = []
    if updatesWithPts.count != 0 {
        groups.append(.withPts(updates: updatesWithPts, users: users, chats: chats))
    }
    if updatesWithQts.count != 0 {
        groups.append(.withQts(updates: updatesWithQts, users: users, chats: chats))
    }
    
    if let seqRange = seqRange {
        groups.append(.withSeq(updates: otherUpdates, seqRange: seqRange, date: date, users: users, chats: chats))
    } else {
        groups.append(.withDate(updates: otherUpdates, date: date, users: users, chats: chats))
    }
    
    return groups
}
