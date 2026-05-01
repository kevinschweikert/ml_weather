#lang racket

(require net/url
         json)

(define url
  "https://api.open-meteo.com/v1/forecast?latitude=53.5507&longitude=9.993&hourly=temperature_2m")

(struct hourly (time temperature) #:transparent)
(struct forecast (latitude longitude timezone hourly) #:transparent)

(define (fetch-url url)
  (call/input-url (string->url url) get-pure-port port->bytes))

(define (parse-forecast json-bytes)
  (let* ([data (bytes->jsexpr json-bytes)]
         [hourly-data (hash-ref data 'hourly)]
         [lat (hash-ref data 'latitude)]
         [long (hash-ref data 'longitude)]
         [tz (hash-ref data 'timezone)]
         [times (hash-ref hourly-data 'time)]
         [temps (hash-ref hourly-data 'temperature_2m)])
    (forecast lat long tz (hourly times temps))))

(define (format-forecast fc)
  (match-define (forecast lat lon tz (hourly times temps)) fc)
  (define header (format "lat: ~a lon: ~a tz: ~a" lat lon tz))
  (define rows
    (for/list ([t (in-list times)]
               [c (in-list temps)])
      (format "~a: ~a" t c)))
  (string-join (cons header rows) "\n"))

(with-handlers ([exn:fail:network? (lambda (e) (eprintf "Request failed: ~a~n" (exn-message e)))]
                [exn:fail? (lambda (e) (eprintf "Invalid payload: ~a~n" (exn-message e)))])
  (displayln (format-forecast (parse-forecast (fetch-url url)))))
