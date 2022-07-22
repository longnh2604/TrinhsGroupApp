//
//  ViewController.swift
//  Testing
//
//  Created by long on 19/07/2022.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        runTest()
    }
    
    func runTest() {
        var tests = [1,2,2,4,6,6,7]
        let unique = tests.unique()
        print(unique)
        let sum = unique.reduce(0, +)
        print(sum)
        
        var a = [1,2]
        var b = a
        a.append(3)
        print(a)
        print(b)
    }
}

extension Array where Element: Hashable {
    func unique() -> [Element] {
        var seen = [Element: Bool]()
        return self.filter({ seen.updateValue(true, forKey: $0) == nil })
    }
}

extension Sequence where Element: Numeric {
    func sum() -> Element {
        return reduce(0, +)
    }
}

