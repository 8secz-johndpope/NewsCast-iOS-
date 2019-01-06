//
//  DaoHandle.swift
//  MyApp
//
//  Created by Jose Adams on 2018/10/16.
//  Copyright © 2018 Jose Adams. All rights reserved.
//

import UIKit

class DaoHandle: NSObject {

    /*CONSTANT*/
    static let FEEDLIST = "FEEDLIST";
    static let ITEMLIST = "ITEMLIST";
    static let PARENT = "parent";
    static let TITLE = "title";
    static let LINK = "link";
    static let DATE = "pubdate";
    static let MARK = "mark";
    static let MEDIA = "media";
    static let SET = "1";
    static let UNSET = "0";
    static let ASC = "ASC";
    static let DESC = "DESC";

    /*ATTRIBUTES*/
    private var _rssData: RssData?;
    private var _rssDataArray: [RssData]?;
    private var _table = "";
    
    private var _response = "";
    private let Notice = NotificationCenter.default;
    private let Queue = DispatchQueue.main;
    
    /*CONSTRUCTOR*/
    
    init(Table table: String, Response response: String)
    {
        _table = table;
        _response = response;
    }
    
    /* GETTER / SETTER */
    
    var RssDataArray: [RssData]
    {
        return _rssDataArray!;
    }
    
    var Table: String
    {
        get
        {
            return _table;
        }
        set
        {
            _table = newValue;
        }
    }
    
    var Response: String
    {
        get
        {
            return _response;
        }
        set
        {
            _response = newValue;
        }
    }

    /* DB Initialization */
    
    /*  Running Environment default Folder
     *  --> Documents
     *  --> SystemData
     *  --> Library
     *  --> tmp
     */
    
    private var dbPath: String
    {
        let targetPath = "\(NSHomeDirectory())/Documents/newscast.sqlite"   /// <-- the running environment
        
        //print("DaoHandle --> file path, running: \(targetPath)");
        
        let sourcePath = Bundle.main.path(forResource: "newscast", ofType: "sqlite")!  // the ide environment
        
        //print("DaoHandle --> file path, developing: \(sourcePath)");
        
        let file = FileManager.default;
        
        if !file.fileExists(atPath: targetPath)
        {
            try? file.copyItem(atPath: sourcePath, toPath: targetPath);
        }
        
        return targetPath;
    }
    
    /*METHOD*/
    
    private func throwMessage(_ message: String)
    {
        Notice.post(name:Notification.Name(rawValue: _response), object: nil, userInfo: ["DaoHandle":message])
    }
    
    func fetchDataArray()
    {
        print("DaoHandle --> fetching");
        
        Queue.async
        {
            var message = ""
            
            self._rssDataArray = self.getDataArray();
            
            let size = self._rssDataArray!.count;
            
            print("DaoHandle --> RssDataArray's size: \(size)")
            
            if size > 0
            {
                print("DaoHandle --> fetched");
                
                message = "FETCHED";
            }
            else
            {
                print("DaoHandle --> empty");
                
                message = "EMPTY";
            }
            
            self.throwMessage(message);
        }
    }
    
    func fetchDataArray(Column column: String, Like like: String)
    {
        print("DaoHandle --> fetching");
        
        Queue.async
        {
            var message = ""
            
            self._rssDataArray = self.getDataArray(column, like);
            
            let size = self._rssDataArray!.count;
            
            print("DaoHandle --> RssDataArray's size: \(size)")
            
            if size > 0
            {
                print("DaoHandle --> fetched");
                
                message = "FETCHED";
            }
            else
            {
                print("DaoHandle --> empty");
                
                message = "EMPTY";
            }
            
            self.throwMessage(message);
        }
    }
    
    func fetchDataArray(Column column: String, Like like: String, Order order: String, Sort sort: String)
    {
        print("DaoHandle --> fetching");
        
        Queue.async
        {
            var message = ""
        
            self._rssDataArray = self.getDataArray(column, like, order, sort);
            
            let size = self._rssDataArray!.count;
            
            print("DaoHandle --> RssDataArray's size: \(size)")
            
            if size > 0
            {
                print("DaoHandle --> fetched");
                
                message = "FETCHED";
            }
            else
            {
                print("DaoHandle --> empty");
                
                message = "EMPTY";
            }
            
            self.throwMessage(message);
        }
    }
    
    func fetchDataArrayFuzzy(Column column: String, Like like: String)
    {
        print("DaoHandle --> fetching");
        
        Queue.async
        {
            var message = ""
            
            self._rssDataArray = self.getDataArrayFuzzy(column, like);
            
            let size = self._rssDataArray!.count;
            
            print("DaoHandle --> RssDataArray's size: \(size)")
            
            if size > 0
            {
                print("DaoHandle --> fetched");
                
                message = "FETCHED";
            }
            else
            {
                print("DaoHandle --> empty");
                
                message = "EMPTY";
            }
            
            self.throwMessage(message);
        }
    }
    
    func fetchDataArrayFuzzy(Column column: String, Like like: String, Order order: String, Sort sort: String)
    {
        print("DaoHandle --> fetching");
        
        Queue.async
            {
                var message = ""
                
                self._rssDataArray = self.getDataArrayFuzzy(column, like, order, sort);
                
                let size = self._rssDataArray!.count;
                
                print("DaoHandle --> RssDataArray's size: \(size)")
                
                if size > 0
                {
                    print("DaoHandle --> fetched");
                    
                    message = "FETCHED";
                }
                else
                {
                    print("DaoHandle --> empty");
                    
                    message = "EMPTY";
                }
                
                self.throwMessage(message);
        }
    }
    
    func fetchDataArrayMedia(Column column: String?, Like like: String?, Order order: String?, Sort sort: String?)
    {
        print("DaoHandle --> fetching");
        
        Queue.async
        {
            var message = ""
            
            self._rssDataArray = self.getDataArrayMedia(column, like, order, sort);
            
            let size = self._rssDataArray!.count;
            
            print("DaoHandle --> RssDataArray's size: \(size)")
            
            if size > 0
            {
                print("DaoHandle --> fetched");
                
                message = "FETCHED";
            }
            else
            {
                print("DaoHandle --> empty");
                
                message = "EMPTY";
            }
            
            self.throwMessage(message);
        }
    }
    
    func insertData(_ data: RssData)
    {
        print("DaoHandle --> single inserting");
        
        Queue.async
        {
            var message = ""
            
            let id = self.checkData(data);
            
            if id > 0
            {
                print("DaoHandle --> data existed, skipped");
                
                message = "EXISTED";
            }
            else
            {
                print("DaoHandle --> inserting");
                
                if self.insert(data)
                {
                    message =  "INSERTED";
                }
                else
                {
                    message = "INSERT_FAILED";
                }
            }
            
            self.throwMessage(message);
        }
    }
    
    func insertDataWithUpdate(_ data: RssData)
    {
        print("DaoHandle --> single inserting");
        
        Queue.async
        {
            var message = ""
            
            let id = self.checkData(data);
            
            if id > 0
            {
                print("DaoHandle --> data existed, updating instead");
                
                data.Sid = id;
                
                if self.update(data)
                {
                    message =  "UPDATED_INSTEAD";
                }
                else
                {
                    message = "INSERT_FAILED";
                }
            }
            else
            {
                print("DaoHandle --> inserting");
                
                if self.insert(data)
                {
                    message =  "INSERTED";
                }
                else
                {
                    message = "INSERT_FAILED";
                }
            }
            
            self.throwMessage(message);
        }
    }
    
    func batchInsertDataWithUpdate(_ array: Array<RssData>)
    {
        print("DaoHandle --> batch inserting");
        
        Queue.async
        {
            var message = "BATCH_INSERTED";
        
            for element in array
            {
                let id = self.checkData(element);
                
                if id > 0
                {
                    element.Sid = id;
                    
                    if !self.update(element)
                    {
                        message = "BATCH_INSERT_FAILED"
                        
                        break;
                    }
                }
                else
                {
                    if !self.insert(element)
                    {
                        message = "BATCH_INSERT_FAILED"
                        
                        break;
                    }
                }
            }
        
            self.throwMessage(message);
        }
    }
    
    func updateData(_ data: RssData)
    {
        print("DaoHandle --> single updating");
        
        Queue.async
        {
            var message = "";
            
            let id = self.checkData(data);
            
            if id > 0
            {
                print("DaoHandle --> updating");
                
                if self.update(data)
                {
                    message = "UPDATED";
                }
                else
                {
                    message = "UPDATE_FAILED";
                }
            }
            else
            {
                print("DaoHandle --> data not existed, inserting instead");
                
                if self.insert(data)
                {
                    message =  "INSERTED_INSTEAD";
                }
                else
                {
                    message = "UPDATE_FAILED";
                }
            }
            
            self.throwMessage(message);
        }
    }
    
    func deleteData(_ data: RssData)
    {
        print("DaoHandle --> deleting");
        
        Queue.async
        {
            var message = "";
            
            let sid_int = self.checkData(data);
            let sid_ext = data.Sid;
            
            if sid_ext == sid_int
            {
                if self.delete(data)
                {
                    message = "DELETED";
                }
                else
                {
                    message = "DELETE_FAILED";
                }
            }
            else
            {
                message = "NOTHING_DELETED";
            }
            
            self.throwMessage(message);
        }
    }
    
    func deleteItemDataWithDefaultExceptionAndOlderThan(_ pastday: String)
    {
        print("DaoHandle --> cleaning up");
        
        Queue.async
        {
            let message = "CLEANED_UP";
        
            let array = self.getItemDataWithDefaultExceptionAndOlderThan(pastday)
        
            for element in array
            {
                if self.delete(element)
                {
                    print("DaoHandle --> one data-delete successful")
                }
                else
                {
                    print("DaoHandle --> one data-delete failed")
                }
            }
        
            self.throwMessage(message);
        }
    }
    
    func deleteItemDataWithDefaultExceptionAndParentIs(_ parent: String)
    {
        print("DaoHandle --> unsubscribing");
        
        Queue.async
        {
            let message = "UNSUBSCRIBED";
            
            let array = self.getItemDataWithDefaultExceptionAndParentIs(parent);
            
            for element in array
            {
                if self.delete(element)
                {
                    print("DaoHandle --> one data-delete successful")
                }
                else
                {
                    print("DaoHandle --> one data-delete failed")
                }
            }
            
            self.throwMessage(message);
        }
    }
    
    /*
     *  SQL ACCESS Extended Method
     * */

    private func checkData(_ data: RssData) -> Int32
    {
        let title = data.Title ?? "";
        let link = data.Link ?? "";
        
        if let data = getOneBy(title: title, link: link)
        {
            let id = data.Sid!;
            
            return id;
        }
        else
        {
            return -1;
        }
    }
    
    /*
     *  SQL ACCESS Basic Method
     * */

    /*
     *  where FMDatabase has several methods as followings
     *  01. open()
     *  02. close()
     *  03. executeQuery() -> FMResultSet!
     *  88. everything about sqlite date command are supported, such as between, >, =, <.
     *
     *  where the FMResultSet has severl methods as followings
     *  01. next()
     *  02. int()
     *  03. string()
     *  04. data()  <-- for byte code
     *  88. everything about sqlite's datetime is queried by string() method
     */

    private func getDataArray() -> Array<RssData>
    {
        var array = Array<RssData>();
        
        let db = FMDatabase(path: dbPath)
        
        db!.open();

        let sql_cmd = "SELECT * FROM \(_table)";

        print("DaoHandle --> SQL: \(sql_cmd)");
        
        if let resultSet = db!.executeQuery(sql_cmd, withArgumentsIn: [])
        {
            while resultSet.next()
            {
                let data = RssData();

                data.fromFM(ResultSet: resultSet);

                array.append(data);
            }

            resultSet.close();
        }

        db!.close()
        
        return array;
    }
    
    private func getDataArray(_ column: String, _ like: String) -> Array<RssData>
    {
        var alike = like;
        
        if alike.contains("'")
        {
            alike = alike.replacingOccurrences(of: "'", with: "_");
        }
        
        var array = Array<RssData>();
        
        let db = FMDatabase(path: dbPath)
        
        db!.open();
        
        let sql_cmd = "SELECT * FROM \(_table) WHERE \(column) LIKE '\(alike)'";
        
        print("DaoHandle --> SQL: \(sql_cmd)");
        
        if let resultSet = db!.executeQuery(sql_cmd, withArgumentsIn: [])
        {
            while resultSet.next()
            {
                let data = RssData();
                
                data.fromFM(ResultSet: resultSet);
                
                array.append(data);
            }
            
            resultSet.close();
        }
        
        db!.close()
        
        return array;
    }
    
    private func getDataArray(_ column: String, _ like: String, _ order: String, _ sort: String) -> Array<RssData>
    {
        var alike = like;
        
        if alike.contains("'")
        {
            alike = alike.replacingOccurrences(of: "'", with: "_");
        }
        
        var array = Array<RssData>();
        
        let db = FMDatabase(path: dbPath)
        
        db!.open();
        
        let sql_cmd = "SELECT * FROM \(_table) WHERE \(column) LIKE '\(alike)' ORDER BY \(order) \(sort)";
        
        print("DaoHandle --> SQL: \(sql_cmd)");
        
        if let resultSet = db!.executeQuery(sql_cmd, withArgumentsIn: [])
        {
            while resultSet.next()
            {
                let data = RssData();
                
                data.fromFM(ResultSet: resultSet);
                
                array.append(data);
            }
            
            resultSet.close();
        }
        
        db!.close()
        
        return array;
    }
    
    private func getDataArrayMedia(_ column: String?, _ like: String?, _ order: String?, _ sort: String?) -> Array<RssData>
    {
        var array = Array<RssData>();
        
        let db = FMDatabase(path: dbPath)
        
        db!.open();
        
        var sql_cmd = ""
        
        if column != nil && like != nil
        {
            var alike = like;
            
            if alike!.contains("'")
            {
                alike = alike!.replacingOccurrences(of: "'", with: "_");
            }
            
            sql_cmd = "SELECT * FROM \(_table) WHERE \(column!) LIKE '\(alike!)' AND ( \(DaoHandle.MEDIA) LIKE '%.mp3' OR \(DaoHandle.MEDIA) LIKE '%.mp4' ) ";
        }
        else if order != nil && sort != nil
        {
            sql_cmd = "SELECT * FROM \(_table) WHERE ( \(DaoHandle.MEDIA) LIKE '%.mp3' OR \(DaoHandle.MEDIA) LIKE '%.mp4' ) ORDER BY \(order!) \(sort!)";
        }
        else
        {
            return array;
        }
        
        print("DaoHandle --> SQL: \(sql_cmd)");
        
        if let resultSet = db!.executeQuery(sql_cmd, withArgumentsIn: [])
        {
            while resultSet.next()
            {
                let data = RssData();
                
                data.fromFM(ResultSet: resultSet);
                
                array.append(data);
            }
            
            resultSet.close();
        }
        
        db!.close()
        
        return array;
    }
    
    private func getDataArrayFuzzy(_ column: String, _ like: String) -> Array<RssData>
    {
        var alike = like;
        
        if alike.contains("'")
        {
            alike = alike.replacingOccurrences(of: "'", with: "_");
        }
        
        var array = Array<RssData>();
        
        let db = FMDatabase(path: dbPath)
        
        db!.open();
        
        let sql_cmd = "SELECT * FROM \(_table) WHERE \(column) LIKE '%\(alike)%'";
        
        print("DaoHandle --> SQL: \(sql_cmd)");
        
        if let resultSet = db!.executeQuery(sql_cmd, withArgumentsIn: [])
        {
            while resultSet.next()
            {
                let data = RssData();
                
                data.fromFM(ResultSet: resultSet);
                
                array.append(data);
            }
            
            resultSet.close();
        }
        
        db!.close()
        
        return array;
    }
    
    private func getDataArrayFuzzy(_ column: String, _ like: String, _ order: String, _ sort: String) -> Array<RssData>
    {
        var alike = like;
        
        if alike.contains("'")
        {
            alike = alike.replacingOccurrences(of: "'", with: "_");
        }
        
        var array = Array<RssData>();
        
        let db = FMDatabase(path: dbPath)
        
        db!.open();
        
        let sql_cmd = "SELECT * FROM \(_table) WHERE \(column) LIKE '%\(alike)%' ORDER BY \(order) \(sort)";
        
        print("DaoHandle --> SQL: \(sql_cmd)");
        
        if let resultSet = db!.executeQuery(sql_cmd, withArgumentsIn: [])
        {
            while resultSet.next()
            {
                let data = RssData();
                
                data.fromFM(ResultSet: resultSet);
                
                array.append(data);
            }
            
            resultSet.close();
        }
        
        db!.close()
        
        return array;
    }
    
    private func getItemDataWithDefaultExceptionAndParentIs(_ parent: String) -> Array<RssData>
    {
        var aparent = parent;
        
        if aparent.contains("'")
        {
            aparent = aparent.replacingOccurrences(of: "'", with: "_");
        }
        
        var array = Array<RssData>();
        
        let db = FMDatabase(path: dbPath)
        
        db!.open();
        
        let sql_cmd = "SELECT * FROM \(DaoHandle.ITEMLIST) WHERE \(DaoHandle.PARENT) LIKE '\(aparent)' AND ( \(DaoHandle.MARK) IS NULL OR \(DaoHandle.MARK) NOT LIKE '\(DaoHandle.SET)' ) AND ( \(DaoHandle.MEDIA) IS NULL OR \(DaoHandle.MEDIA) NOT LIKE '%.mp3' OR \(DaoHandle.MEDIA) NOT LIKE '%.mp4' )" ;
        
        print("DaoHandle --> SQL: \(sql_cmd)");
        
        if let resultSet = db!.executeQuery(sql_cmd, withArgumentsIn: [])
        {
            while resultSet.next()
            {
                let data = RssData();
                
                data.fromFM(ResultSet: resultSet);
                
                array.append(data);
            }
            
            resultSet.close();
        }
        
        db!.close()
        
        return array;
    }
    
    private func getItemDataWithDefaultExceptionAndOlderThan(_ date: String) -> Array<RssData>
    {
        var array = Array<RssData>();
        
        let db = FMDatabase(path: dbPath)
        
        db!.open();
        
        let sql_cmd = "SELECT * FROM \(DaoHandle.ITEMLIST) WHERE \(DaoHandle.DATE) < '\(date)' AND ( \(DaoHandle.MARK) IS NULL OR \(DaoHandle.MARK) NOT LIKE '\(DaoHandle.SET)' ) AND ( \(DaoHandle.MEDIA) IS NULL OR \(DaoHandle.MEDIA) NOT LIKE '%.mp3' OR \(DaoHandle.MEDIA) NOT LIKE '%.mp4' )" ;
        
        print("DaoHandle --> SQL: \(sql_cmd)");
        
        if let resultSet = db!.executeQuery(sql_cmd, withArgumentsIn: [])
        {
            while resultSet.next()
            {
                let data = RssData();
                
                data.fromFM(ResultSet: resultSet);
                
                array.append(data);
            }
            
            resultSet.close();
        }
        
        db!.close()
        
        return array;
    }
    
    private func getOneBy(sid: Int) -> RssData?
    {
        var data: RssData?;
        
        let db = FMDatabase(path: dbPath)
        
        let sql_cmd = "SELECT * FROM \(_table) WHERE sid = \(sid)"

        print("DaoHandle --> SQL: \(sql_cmd)");
        
        db!.open()

        if let resultSet = db!.executeQuery(sql_cmd, withArgumentsIn: [])
        {
            while resultSet.next()
            {
                data = RssData();

                data!.fromFM(ResultSet: resultSet);
            }

            resultSet.close();
        }

        db!.close()

        return data
    }
    private func getOneBy(title: String, link: String) -> RssData?
    {
        var atitle = title;
        
        if atitle.contains("'")
        {
            atitle = atitle.replacingOccurrences(of: "'", with: "_");
        }
        
        var data: RssData?;
        
        let db = FMDatabase(path: dbPath)
        
        let sql_cmd = "SELECT * FROM \(_table) WHERE \(DaoHandle.TITLE) LIKE '\(atitle)' AND \(DaoHandle.LINK) LIKE '\(link)' "
        
        print("DaoHandle --> SQL: \(sql_cmd)");
        
        db!.open()
        
        if let resultSet = db!.executeQuery(sql_cmd, withArgumentsIn: [])
        {
            if resultSet.next()
            {
                data = RssData();
                
                data!.fromFM(ResultSet: resultSet);
            }
            
            resultSet.close();
        }
        
        db!.close()
        
        return data
    }
    
    private func insert(_ data: RssData) -> Bool
    {
        let dict = data.toDictionary(Table: _table);
        
        var columnSeries: String = "";
        
        var keySeries: String = "";
        
        for key in dict.keys
        {
            columnSeries += " \(key),"
            keySeries += " :\(key),"
        }
        
        columnSeries.removeFirst(); //get rid of space
        columnSeries.removeLast(); //get rid of comma
        
        keySeries.removeFirst(); //get rid of space
        keySeries.removeLast(); //get rid of comma
        
        let db = FMDatabase(path: dbPath)
        
        /*let sql_cmd = "INSERT INTO contacts (name, addr, photo) VALUES (:dict_Name, :dict_Addr, :dict_Photo);"*/
        let sql_cmd = "INSERT INTO \(_table) (\(columnSeries)) VALUES (\(keySeries))"
        
        print("DaoHandle --> SQL: \(sql_cmd)");
        
        db!.open();

        var successful = false;
        
        if db!.executeUpdate(sql_cmd, withParameterDictionary: dict)
        {
            successful = true;
        }
        
        db!.close();
        
        return successful;
    }
    
    private func update(_ data: RssData) -> Bool
    {
        var dict = data.toDictionary(Table: _table);
        
        dict["sid"] = data.Sid; //has to be done manully here; do not remove it...
        
        var keySeries: String = "";
        
        for key in dict.keys
        {
            keySeries += " \(key) = :\(key),"
        }
        
        keySeries.removeFirst(); //get rid of space
        keySeries.removeLast(); //get rid of comma
        
        let db = FMDatabase(path: dbPath)

        /*let sql_cmd = "UPDATE contacts SET name = :dict_Name, addr = :dict_Addr, photo = :dict_Photo WHERE sid = :dict_Sid;"*/
        let sql_cmd = "UPDATE \(_table) SET \(keySeries) WHERE sid = :sid"

        print("DaoHandle --> SQL: \(sql_cmd)");
        
        db!.open();

        var successful = false;
        
        if db!.executeUpdate(sql_cmd, withParameterDictionary: dict)
        {
            successful = true
        }
        
        db!.close();
        
        return successful;
    }
    
    private func delete(_ data: RssData) -> Bool
    {
        var dict = data.toDictionary(Table: _table);
        
        let sid = data.Sid;
        
        dict["sid"] = sid; //has to be done manully here; do not remove it...
        
        var keySeries: String = "";
        
        for key in dict.keys
        {
            keySeries += " \(key) = :\(key),"
        }
        
        keySeries.removeFirst(); //get rid of space
        keySeries.removeLast(); //get rid of comma
        
        let db = FMDatabase(path: dbPath)
        
        let sql_cmd = "DELETE FROM \(_table) WHERE sid = :sid"
        
        print("DaoHandle --> SQL: \(sql_cmd), where sid = \(sid ?? -1)");
        
        db!.open();
        
        var successful = false;
        
        if db!.executeUpdate(sql_cmd, withParameterDictionary: dict)
        {
            successful = true;
        }
        
        db!.close();
        
        return successful;
    }
}
