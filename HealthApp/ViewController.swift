//
//  ViewController.swift
//  HealthApp
//
//  Created by Nyisztor, Karoly on 8/4/18.
//  Copyright © 2018 Nyisztor, Karoly. All rights reserved.
//

import UIKit
import HealthKit

enum PermissionError: Error {
    case stepDataReadError
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if HKHealthStore.isHealthDataAvailable() {
            requestPermission { success, error in
                if success {
                    self.queryTodaysSteps { (steps) in
                        print(steps)
                    }
                } else {
                    print(error ?? "Unknown error")
                }
            }

        }
    }
    
    private func requestPermission(completion: @escaping (Bool, Error?) -> Void) {
        guard let stepQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
            completion(false, PermissionError.stepDataReadError)
            return
        }
        
        let types = Set([stepQuantityType])
        
        let healthStore = HKHealthStore()
        healthStore.requestAuthorization(toShare: nil, read: types) { success, error in
            completion(success, error)
        }
    }
    
    private func queryTodaysSteps(completion: @escaping (Double) -> Void) {
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: today, options: .strictStartDate)

        guard let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        
        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: HKStatisticsOptions.cumulativeSum) { (statsQuery, result, error) in
            if let queryError = error {
                print(queryError)
                completion(0)
                return
            }
            
            guard let steps = result?.sumQuantity() else {
                completion(0)
                return
            }
            completion(steps.doubleValue(for: HKUnit.count()))
        }
        
        let healthStore = HKHealthStore()
        healthStore.execute(query)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

