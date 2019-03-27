import Foundation

// Protocols definition

public protocol ConfigurableWithVM: class {
    func configure(with viewModel: IdentifiableVMProtocol)
}

public protocol ConfigurableTableViewCell: ConfigurableWithVM {
    associatedtype Model: IdentifiableVMProtocol

    func configure(with object: Model)
}

public extension ConfigurableTableViewCell {
    func configure(with viewModel: IdentifiableVMProtocol) {
        if let model = viewModel as? Model {
            self.configure(with: model)
        }
    }
}

public protocol IdentifiableVMProtocol {
    var typeID: AnyTypeID { get }
}

public protocol TableViewVMProtocol {
    var title: String? { get }
    var sections: [TableViewSectionVMProtocol] { get }
    var header: IdentifiableVMProtocol? { get }
    var footer: IdentifiableVMProtocol? { get }

    func numberOfSections() -> Int
    func numberOfRows(inSection section: Int) -> Int

    func viewModel(at indexPath: IndexPath) -> TableViewCellVMProtocol
    func viewModelForHeader(inSection section: Int) -> IdentifiableVMProtocol?
    func viewModelForFooter(inSection section: Int) -> IdentifiableVMProtocol?

    func canSelectViewModel(at indexPath: IndexPath) -> Bool
    func selectViewModel(at indexPath: IndexPath)

    func firstIndexPath(withViewModelTypeID typeID: AnyTypeID) -> IndexPath?

    func reloadData()

    var titleDidChange: ((String?) -> Void)? { get set }
    var headerDidChange: ((IdentifiableVMProtocol?) -> Void)? { get set }
    var footerDidChange: ((IdentifiableVMProtocol?) -> Void)? { get set }
    var reloadDataFinished: ((Error?) -> Void)? { get set }
}

public protocol TableViewSectionVMProtocol {
    var rows: [TableViewCellVMProtocol] { get }
    var header: IdentifiableVMProtocol? { get }
    var footer: IdentifiableVMProtocol? { get }
}

public protocol TableViewCellVMProtocol: IdentifiableVMProtocol {
    var isSelectable: Bool { get }
    func select()
}

// Extend protocols for implementation of methods and default values for properties

public extension IdentifiableVMProtocol {
}

public extension TableViewVMProtocol {
    var title: String? { return nil }
    var sections: [TableViewSectionVMProtocol] { return [] }
    var header: IdentifiableVMProtocol? { return nil }
    var footer: IdentifiableVMProtocol? { return nil }

    func numberOfSections() -> Int {
        return sections.count
    }

    func numberOfRows(inSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func viewModel(at indexPath: IndexPath) -> TableViewCellVMProtocol {
        return sections[indexPath.section].rows[indexPath.row]
    }

    func viewModelForHeader(inSection section: Int) -> IdentifiableVMProtocol? {
        return sections[section].header
    }

    func viewModelForFooter(inSection section: Int) -> IdentifiableVMProtocol? {
        return sections[section].footer
    }

    func canSelectViewModel(at indexPath: IndexPath) -> Bool {
        return viewModel(at: indexPath).isSelectable
    }

    func selectViewModel(at indexPath: IndexPath) {
        viewModel(at: indexPath).select()
    }

    func reloadData() {
    }

    func firstIndexPath(withViewModelTypeID typeID: AnyTypeID) -> IndexPath? {
        var sectionIndex: Int = 0
        var rowIndex: Int = 0
        for section in sections {
            rowIndex = 0
            for row in section.rows {
                if row.typeID == typeID {
                    return IndexPath(row: rowIndex, section: sectionIndex)
                }
                rowIndex += 1
            }
            sectionIndex += 1
        }
        return nil
    }

    var titleDidChange: ((String?) -> Void)? {
        get { return nil }
        set {}
    }
    var headerDidChange: ((IdentifiableVMProtocol?) -> Void)? {
        get { return nil }
        set {}
    }
    var footerDidChange: ((IdentifiableVMProtocol?) -> Void)? {
        get { return nil }
        set {}
    }
    var reloadDataFinished: ((Error?) -> Void)? {
        get { return nil }
        set {}
    }

}

public extension TableViewSectionVMProtocol {
    var rows: [TableViewCellVMProtocol] { return [] }
    var header: IdentifiableVMProtocol? { return nil }
    var footer: IdentifiableVMProtocol? { return nil }
}

public extension TableViewCellVMProtocol {
    var isSelectable: Bool { return false }
    func select() {

    }
}

// Convenience structures, useful for simple cases were we don't need to create a new struct/class for a/part of a view model.

public struct TableViewVM: TableViewVMProtocol {
    public var title: String? {
        didSet {
            titleDidChange?(title)
        }
    }
    public var sections: [TableViewSectionVMProtocol] = []
    public var header: IdentifiableVMProtocol? {
        didSet {
            headerDidChange?(header)
        }
    }
    public var footer: IdentifiableVMProtocol? {
        didSet {
            footerDidChange?(footer)
        }
    }

    public var titleDidChange: ((String?) -> Void)?
    public var headerDidChange: ((IdentifiableVMProtocol?) -> Void)?
    public var footerDidChange: ((IdentifiableVMProtocol?) -> Void)?
    public var reloadDataFinished: ((Error?) -> Void)?
}

public struct TableViewSectionVM: TableViewSectionVMProtocol {
    public var rows: [TableViewCellVMProtocol]
    public var header: IdentifiableVMProtocol?
    public var footer: IdentifiableVMProtocol?

    public init(rows: [TableViewCellVMProtocol] = []) {
        self.rows = rows
    }
}

public struct TableViewCellVM: TableViewCellVMProtocol {
    public var typeID: AnyTypeID
    public var isSelectable: Bool
}
