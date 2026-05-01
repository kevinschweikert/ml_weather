open System.Net.Http
open System.Net.Http.Json
open System.Text.Json
open System.Text.Json.Serialization

type Hourly =
    { [<JsonPropertyName("time")>]
      time: string list
      [<JsonPropertyName("temperature_2m")>]
      temperature: float list }

type Forecast =
    { latitude: float
      longitude: float
      timezone: string
      hourly: Hourly }

type WeatherError =
    | HttpError of string
    | ParseError of string

let url =
    "https://api.open-meteo.com/v1/forecast?latitude=53.5507&longitude=9.993&hourly=temperature_2m"

/// Fetches JSON from the given URL and deserializes it into type 'T
let getForecast<'T> (url: string) =
    task {
        try
            use client = new HttpClient()
            let! response = client.GetFromJsonAsync<'T>(url)
            return Ok response
        with
        | :? HttpRequestException as ex -> return Error(HttpError ex.Message)
        | :? JsonException as ex -> return Error(ParseError ex.Message)
    }

let formatForecast (forecast: Forecast) =
    let header =
        $"lat: {forecast.latitude} lon: {forecast.longitude} tz: {forecast.timezone}"

    let rows =
        List.zip forecast.hourly.time forecast.hourly.temperature
        |> List.map (fun (time, temp) -> $"{time}: {temp:F1}")

    header :: rows |> String.concat "\n"


task {
    match! getForecast<Forecast> url with
    | Ok forecast -> printfn "%s" (formatForecast forecast)
    | Error(HttpError msg) -> eprintfn $"Request failed: {msg}"
    | Error(ParseError msg) -> eprintfn $"Invalid payload: {msg}"
}
|> Async.AwaitTask
|> Async.RunSynchronously
