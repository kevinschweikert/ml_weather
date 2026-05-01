open Yojson.Safe.Util

let url =
  "https://api.open-meteo.com/v1/forecast?latitude=53.5507&longitude=9.993&hourly=temperature_2m"

type hourly = { time : string list; temperature : float list }

type forecast = {
  latitude : float;
  longitude : float;
  timezone : string;
  hourly : hourly;
}

type weather_error = ParseError of string | HttpError of string

let fetch_url url =
  Ezcurl.get ~url ()
  |> Result.map_error (fun (_code, reason) -> HttpError reason)
  |> Result.map (fun response -> response.Ezcurl.body)

let parse_forecast json_string =
  try
    let json = Yojson.Safe.from_string json_string in
    let hourly = json |> member "hourly" in
    let lat = json |> member "latitude" |> to_number in
    let long = json |> member "longitude" |> to_number in
    let tz = json |> member "timezone" |> to_string in
    let temperatures_2m =
      hourly |> member "temperature_2m" |> convert_each to_number
    in
    let times = hourly |> member "time" |> convert_each to_string in
    Ok
      {
        latitude = lat;
        longitude = long;
        timezone = tz;
        hourly = { temperature = temperatures_2m; time = times };
      }
  with
  | Type_error (reason, _json) -> Error (ParseError reason)
  | Yojson.Json_error reason -> Error (ParseError reason)

let format_forecast forecast =
  let header =
    Printf.sprintf "lat: %g lon: %g tz: %s" forecast.latitude forecast.longitude
      forecast.timezone
  in
  let rows =
    List.combine forecast.hourly.time forecast.hourly.temperature
    |> List.map (fun (time, temp) -> Printf.sprintf "%s: %.1f" time temp)
  in
  header :: rows |> String.concat "\n"

let () =
  match Result.bind (fetch_url url) parse_forecast with
  | Ok forecast -> print_endline (format_forecast forecast)
  | Error (HttpError msg) -> Printf.eprintf "Request failed: %s\n" msg
  | Error (ParseError msg) -> Printf.eprintf "Invalid payload: %s\n" msg
