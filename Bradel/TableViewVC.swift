import UIKit

open class TableViewVC<VMType: TableViewVMProtocol>: UIViewController, UITableViewDelegate, UITableViewDataSource {
    public var tableView: UITableView
    public var viewModel: VMType? {
        didSet {
            title = viewModel?.title
        }
    }

    public var clearsSelectionOnViewWillAppear: Bool = false

    public init(style: UITableViewStyle) {
        tableView = UITableView(frame: CGRect.zero, style: style)
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        tableView = UITableView(frame: CGRect.zero, style: .grouped)
        super.init(coder: aDecoder)
    }

    open func typeMapping() -> [AnyTypeID: AnyClass] {
        return [:]
    }

    open func registerViews() {
        let mapping = typeMapping()
        for view in mapping {
            let nibName = String(describing: view.value)
            switch view.value {
                case is UITableViewCell.Type:
                    if let nibPath = Bundle.main.path(forResource: nibName, ofType: "nib"), FileManager.default.fileExists(atPath: nibPath) {
                        let nib = UINib(nibName: String(describing: view.value), bundle: nil)
                        tableView.register(nib, forCellReuseIdentifier: view.key.rawValue)
                    } else {
                        tableView.register(view.value, forCellReuseIdentifier: view.key.rawValue)
                    }
                    break
                case is UITableViewHeaderFooterView.Type:
                    if let nibPath = Bundle.main.path(forResource: nibName, ofType: "nib"), FileManager.default.fileExists(atPath: nibPath) {
                        let nib = UINib(nibName: String(describing: view.value), bundle: nil)
                        tableView.register(nib, forHeaderFooterViewReuseIdentifier: view.key.rawValue)
                    } else {
                        tableView.register(view.value, forHeaderFooterViewReuseIdentifier: view.key.rawValue)
                    }
                    break
                default: break
            }
        }
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let headerView = tableView.tableHeaderView else { return }

        let size = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)

        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
            tableView.tableHeaderView = headerView
            tableView.layoutIfNeeded()
        }
    }

   open override func viewDidLoad() {
        super.viewDidLoad()

        registerViews()

        title = viewModel?.title

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44 // Default cell height
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = tableView.style == .plain ? 22 : 10 // Default header height
        tableView.sectionFooterHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionFooterHeight = tableView.style == .plain ? 22 : 10 // Default footer height
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        view.topAnchor.constraint(equalTo: tableView.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: tableView.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor).isActive = true

        viewModel?.titleDidChange = { [weak self] title in
            self?.title = title
        }

        viewModel?.headerDidChange = { [weak self] header in
            if let header = header {
                self?.tableView.tableHeaderView = self?.headerFooterView(for: header)
            } else {
                // .grouped tableView have by default a margin at top. Keep this behavior
                if self?.tableView.style == .grouped {
                    self?.tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 35)) // Default first section height
                } else {
                    self?.tableView.tableHeaderView = nil
                }
                self?.tableView.layoutIfNeeded()
            }
        }

        viewModel?.footerDidChange = { [weak self] footer in
            if let footer = footer {
                self?.tableView.tableFooterView = self?.headerFooterView(for: footer)
            } else {
                self?.tableView.tableFooterView = nil
            }
        }

        viewModel?.reloadDataFinished = { [weak self] error in
            self?.tableView.reloadData()
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
    }

    // Data

    open func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel?.sections.count ?? 0
    }

    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.sections[section].rows.count ?? 0
    }

    // TableView Elements

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellVM = viewModel?.viewModel(at: indexPath) else {
            fatalError ("No view model provided for cell at indexPath {\(indexPath.section), \(indexPath.row)}")
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: cellVM.typeID.rawValue, for: indexPath)
        if let cell = cell as? ConfigurableWithVM {
            cell.configure(with: cellVM)
        }

        return cell
    }
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let viewModel = self.viewModel?.viewModelForHeader(inSection: section) else { return nil }
        guard typeMapping()[viewModel.typeID] is UIView.Type else { return nil }

        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: viewModel.typeID.rawValue)
        if let headerView = headerView as? ConfigurableWithVM {
            headerView.configure(with: viewModel)
        }

        return headerView
    }
    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let viewModel = self.viewModel?.viewModelForFooter(inSection: section) else { return nil }
        guard typeMapping()[viewModel.typeID] is UIView.Type else { return nil }

        let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: viewModel.typeID.rawValue)
        if let footerView = footerView as? ConfigurableWithVM {
            footerView.configure(with: viewModel)
        }

        return footerView
    }

    // Heights

    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    // Selection
    
    open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return viewModel?.canSelectViewModel(at: indexPath) ?? false
    }
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel?.selectViewModel(at: indexPath)
    }

    open func headerFooterView(for viewModel: IdentifiableVMProtocol) -> UIView? {
        guard let headerFooterViewClass = typeMapping()[viewModel.typeID] as? UIView.Type else { return nil }
        let headerFooterView = headerFooterViewClass.init(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 40))

        if let configurableHeaderFooterView = headerFooterView as? ConfigurableWithVM {
            configurableHeaderFooterView.configure(with: viewModel)
        }

        return headerFooterView
    }
}
