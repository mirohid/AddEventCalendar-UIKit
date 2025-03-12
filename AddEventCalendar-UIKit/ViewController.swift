//
//  ViewController.swift
//  AddEventCalendar-UIKit
//
//  Created by MacMini6 on 11/03/25.


import UIKit
import EventKit
import FSCalendar
import IQKeyboardManagerSwift

class ViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource{

    @IBOutlet weak var txtEvent: UITextField!{
        didSet{
            txtEvent.layer.cornerRadius = 20
            txtEvent.layer.shadowColor = UIColor.black.cgColor
            txtEvent.layer.shadowOpacity = 0.3
            txtEvent.layer.shadowOffset = CGSize(width: 0, height: 4)
            txtEvent.layer.shadowRadius = 5
            txtEvent.backgroundColor = UIColor.systemGray6
        }
    }
    @IBOutlet weak var btnAdd: UIButton!{
        didSet{
            btnAdd.layer.cornerRadius = 20
        }
    }
    @IBOutlet weak var calendarView: FSCalendar!{
        didSet {
            calendarView.layer.cornerRadius = 20
            calendarView.layer.shadowColor = UIColor.black.cgColor
            calendarView.layer.shadowOpacity = 0.3
            calendarView.layer.shadowOffset = CGSize(width: 0, height: 4)
            calendarView.layer.shadowRadius = 5
            calendarView.backgroundColor = UIColor.systemGray6
        }
    }
    @IBOutlet weak var EventView: UIView!{
        didSet{
            EventView.layer.cornerRadius = 20
            EventView.layer.shadowColor = UIColor.black.cgColor
            EventView.layer.shadowOpacity = 0.3
            EventView.layer.shadowOffset = CGSize(width: 0, height: 4)
            EventView.layer.shadowRadius = 5
            EventView.backgroundColor = UIColor.systemGray6
        }
    }
    
    let eventStore = EKEventStore()
    var selectedDate: Date = Date()
    var eventDates: Set<Date> = []


    override func viewDidLoad() {
        super.viewDidLoad()
        setupCalendar()
        setupAnimations()
        requestCalendarAccess()// Request permission & fetch events
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            fetchEventsFromCalendar() // Fetch events every time view appears
        }
    
    func setupCalendar() {
          calendarView.delegate = self
          calendarView.dataSource = self
      }
      
      func setupAnimations() {
          btnAdd.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
          UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
              self.btnAdd.transform = .identity
          })
      }
      
      func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
          selectedDate = date
      }
    
    
    @IBAction func addBtnClicked(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
               sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
           }) { _ in
               UIView.animate(withDuration: 0.1) {
                   sender.transform = .identity
               }
           }

           guard let eventText = txtEvent.text, !eventText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
               showAlert(title: "Error", message: "Event title cannot be empty.")
               return
           }

           requestCalendarAccess()
    }
    func requestCalendarAccess() {
           eventStore.requestAccess(to: .event) { granted, error in
               if granted {
                   self.addEventToCalendar()
                   self.fetchEventsFromCalendar() // Fetch events after adding
               } else {
                   print("Access Denied: \(error?.localizedDescription ?? "Unknown error")")
               }
           }
       }
        
    func addEventToCalendar() {
        guard let eventText = txtEvent.text, !eventText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Error", message: "Event title cannot be empty.")
            return
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = eventText
        event.startDate = selectedDate
        event.endDate = selectedDate.addingTimeInterval(3600) // 1-hour event
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
            eventDates.insert(selectedDate) // Store the event date

            DispatchQueue.main.async {
                self.calendarView.reloadData() // Refresh FSCalendar
                self.txtEvent.text = "" // Clear the text field
                self.showAlert(title: "Success", message: "Event added to Calendar!")
            }
        } catch {
            DispatchQueue.main.async {
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    func fetchEventsFromCalendar() {
           let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
           let endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
           let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
           
           let events = eventStore.events(matching: predicate)
           
           DispatchQueue.main.async {
               self.eventDates.removeAll() // Clear previous data
               
               for event in events {
                   self.eventDates.insert(event.startDate)
               }
               
               self.calendarView.reloadData() // Refresh FSCalendar
           }
       }

    
    func showAlert(title: String, message: String) {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
        }
    }
}

extension ViewController: FSCalendarDelegateAppearance {
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        return eventDates.contains { Calendar.current.isDate($0, inSameDayAs: date) } ? 1 : 0
    }
}
