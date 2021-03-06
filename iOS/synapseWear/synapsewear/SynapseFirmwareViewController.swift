//
//  SynapseFirmwareViewController.swift
//  synapsewear
//
//  Copyright © 2018年 art and program, Inc. For license and other information refer to https://github.com/artandprogram/synapseWear. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class SynapseFirmwareViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    // const
    let settingFileManager: SettingFileManager = SettingFileManager()
    // variables
    var firmwareURL: String = ""
    var firmwares: [[String: Any]] = []
    // views
    var settingTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.getFirmwareData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let nav = self.navigationController as? NavigationController {
            nav.headerTitle.text = "Firmware Update"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func setParam() {
        super.setParam()
    }

    override func setView() {
        super.setView()

        self.view.backgroundColor = UIColor.grayBGColor

        let x:CGFloat = 0
        var y:CGFloat = 0
        let w:CGFloat = self.view.frame.width
        var h:CGFloat = self.view.frame.height
        if let nav = self.navigationController as? NavigationController {
            y = nav.headerView.frame.origin.y + nav.headerView.frame.size.height
            h -= y
        }
        self.settingTableView = UITableView()
        self.settingTableView.frame = CGRect(x: x, y: y, width: w, height: h)
        self.settingTableView.backgroundColor = UIColor.clear
        self.settingTableView.separatorStyle = UITableViewCellSeparatorStyle.none
        self.settingTableView.delegate = self
        self.settingTableView.dataSource = self
        self.view.addSubview(self.settingTableView)
    }

    // MARK: mark - FirmwareData methods

    func getFirmwareData() {

        self.setHiddenLoadingView(false)

        let apiFirmware: ApiFirmware = ApiFirmware(url: self.firmwareURL)
        apiFirmware.getFirmwareDataRequest(success: {
            (json: JSON?) in

            if let res = json, let firmwares = res["firmware"].array {
                self.firmwares = []
                for firmware in firmwares {
                    var data: [String: Any] = [:]
                    if let iosVer = firmware["ios_version"].string {
                        data["ios_version"] = iosVer
                    }
                    else if let iosVer = firmware["ios_version"].number {
                        data["ios_version"] = iosVer
                    }
                    if let devVer = firmware["device_version"].string {
                        data["device_version"] = devVer
                    }
                    else if let devVer = firmware["device_version"].number {
                        data["device_version"] = devVer
                    }
                    if let hexFile = firmware["hex_file"].string {
                        data["hex_file"] = hexFile
                    }
                    if let date = firmware["date"].string {
                        data["date"] = date
                    }
                    //print("data: \(data)")

                    if let devVer = data["device_version"], let checkVer = self.checkAppVersion(String(describing: devVer)) {
                        if checkVer == ComparisonResult.orderedSame || checkVer == ComparisonResult.orderedAscending {
                            self.firmwares.append(data)
                        }
                    }
                }
            }

            self.setHiddenLoadingView(true)
            self.settingTableView.reloadData()
        }, fail: {
            (error: Error?) in
            print("res -> error: \(String(describing: error))")

            self.setHiddenLoadingView(true)
        })
    }

    func checkAppVersion(_ version: String) -> ComparisonResult? {

        if let infoDic = Bundle.main.infoDictionary, let appVersion = infoDic["CFBundleShortVersionString"] as? String {
            let appVersions: [String] = appVersion.components(separatedBy: ".")
            let checkVersions: [String] = version.components(separatedBy: ".")
            var appVersionsInt: [Int] = [0, 0, 0]
            if appVersions.count > 0, let major = Int(appVersions[0]) {
                appVersionsInt[0] = major
            }
            if appVersions.count > 1, let minor = Int(appVersions[1]) {
                appVersionsInt[1] = minor
            }
            if appVersions.count > 2, let revision = Int(appVersions[2]) {
                appVersionsInt[2] = revision
            }
            var checkVersionsInt: [Int] = [0, 0, 0]
            if checkVersions.count > 0, let major = Int(checkVersions[0]) {
                checkVersionsInt[0] = major
            }
            if checkVersions.count > 1, let minor = Int(checkVersions[1]) {
                checkVersionsInt[1] = minor
            }
            if checkVersions.count > 2, let revision = Int(checkVersions[2]) {
                checkVersionsInt[2] = revision
            }

            if appVersionsInt[0] > checkVersionsInt[0] || (appVersionsInt[0] == checkVersionsInt[0] && appVersionsInt[1] > checkVersionsInt[1]) || (appVersionsInt[0] == checkVersionsInt[0] && appVersionsInt[1] == checkVersionsInt[1] && appVersionsInt[2] > checkVersionsInt[2]) {
                return ComparisonResult.orderedAscending
            }
            else if appVersionsInt[0] < checkVersionsInt[0] || (appVersionsInt[0] == checkVersionsInt[0] && appVersionsInt[1] < checkVersionsInt[1]) || (appVersionsInt[0] == checkVersionsInt[0] && appVersionsInt[1] == checkVersionsInt[1] && appVersionsInt[2] < checkVersionsInt[2]) {
                return ComparisonResult.orderedDescending
            }
            else {
                return ComparisonResult.orderedSame
            }
        }
        return nil
    }

    // MARK: mark - UITableViewDataSource methods

    func numberOfSections(in tableView: UITableView) -> Int {

        let sections: Int = 1
        return sections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        var num: Int = 0
        if section == 0 {
            num = self.firmwares.count + 2
        }
        return num
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = .none

        if indexPath.section == 0 {
            if indexPath.row == 0 || indexPath.row == self.firmwares.count + 1 {
                cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "line_cell")
                cell.backgroundColor = UIColor.black.withAlphaComponent(0.1)
                cell.selectionStyle = .none
            }
            else if indexPath.row <= self.firmwares.count {
                let cell: SettingTableViewCell = SettingTableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "interval_cell")
                cell.backgroundColor = UIColor.white
                cell.iconImageView.isHidden = true
                cell.textField.isHidden = true
                cell.swicth.isHidden = true
                cell.arrowView.isHidden = true
                cell.useCheckmark = true
                cell.lineView.isHidden = false
                if indexPath.row == self.firmwares.count {
                    cell.lineView.isHidden = true
                }

                let firmware: [String: Any] = self.firmwares[indexPath.row - 1]
                cell.titleLabel.text = ""
                if let devVer = firmware["device_version"] {
                    cell.titleLabel.text = "Device Version \(String(describing: devVer))"
                    if let date = firmware["date"] {
                        cell.titleLabel.text = "\(cell.titleLabel.text!) \(String(describing: date))"
                    }
                }

                cell.checkmarkView.isHidden = true
                if let nav = self.navigationController as? SettingNavigationViewController, let devVer = firmware["device_version"], let devVerAlt = nav.firmwareInfo["device_version"], String(describing: devVer) == String(describing: devVerAlt), let devDate = firmware["date"], let devDateAlt = nav.firmwareInfo["date"], String(describing: devDate) == String(describing: devDateAlt) {
                    cell.checkmarkView.isHidden = false
                }

                return cell
            }
        }
        return cell
    }

    // MARK: mark - UITableViewDelegate methods

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        var height: CGFloat = 0
        if section == 0 {
            height = 44.0
        }
        return height
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        if self.tableView(tableView, heightForHeaderInSection: section) > 0 {
            let view: UIView = UIView()
            view.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: self.tableView(tableView, heightForHeaderInSection: section))
            view.backgroundColor = UIColor.clear
            return view
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        var height: CGFloat = 0
        let cell: SettingTableViewCell = SettingTableViewCell()
        if indexPath.section == 0 {
            if indexPath.row == 0 || indexPath.row == self.firmwares.count + 1 {
                height = 1.0
            }
            else if indexPath.row <= self.firmwares.count {
                height = cell.cellH
            }
        }
        return height
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: false)

        if indexPath.row > 0 && indexPath.row <= self.firmwares.count {
            let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let firmware: [String: Any] = self.firmwares[indexPath.row - 1]
            if let appinfo = appDelegate.appinfo, let host = appinfo["firmware_domain"] as? String, let filename = firmware["hex_file"] as? String, filename.count > 0 {

                self.startDownload("\(host)\(filename)", firmwareInfo: firmware)
                //print("Firmware: \(firmware)")
            }
        }
    }

    // MARK: mark - Firmware File methods

    func startDownload(_ hexUrl: String, firmwareInfo: [String: Any]) -> Void {

        let fileUrl: URL = self.getSaveFileUrl(fileName: hexUrl)
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (fileUrl, [.removePreviousFile, .createIntermediateDirectories])
        }
        print("startDownload: \(fileUrl.absoluteString)")

        self.setHiddenLoadingView(false)

        Alamofire.download(hexUrl, to:destination)
            .downloadProgress { (progress) in
            }
            .responseData { (data) in
                self.setHiddenLoadingView(true)

                if let nav = self.navigationController as? SettingNavigationViewController {
                    nav.updateFirmware(fileUrl, firmwareInfo: firmwareInfo)
                }
        }
    }

    func getSaveFileUrl(fileName: String) -> URL {

        let documentsUrl: URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let nameUrl: URL = URL(string: fileName)!
        let fileUrl: URL = documentsUrl.appendingPathComponent(nameUrl.lastPathComponent)
        //NSLog(fileURL.absoluteString)
        return fileUrl
    }
}
