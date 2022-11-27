let uri = Uri.of_string "https://birru.up.railway.app/"

open Lwt

let body =
  Cohttp_lwt_unix.Client.get uri
  >>= fun (_, body) ->
  body |> Cohttp_lwt.Body.to_string
  >|= fun body -> Yojson.Basic.from_string body

type currency = {selling: float; buying: float; currency: string}

let parse_currency json =
  let open Yojson.Basic.Util in
  let selling = json |> member "selling" |> to_float in
  let buying = json |> member "buying" |> to_float in
  let currency = json |> member "currency" |> to_string in
  {selling; buying; currency}

let colored_string color string = ANSITerminal.sprintf [color] "%s" string

let greenify = colored_string ANSITerminal.green

let yellowify = colored_string ANSITerminal.yellow

let blueify = colored_string ANSITerminal.blue

let make_padding max current = String.make (max - String.length current) ' '

let join sep lst = List.fold_right (fun acc e -> acc ^ sep ^ e) lst ""

let print_currency
    (max_currency_col_width, max_selling_col_width, max_buying_col_width)
    {selling; buying; currency} =
  let currency =
    greenify currency ^ make_padding max_currency_col_width currency
  in
  let selling = string_of_float selling in
  let selling =
    make_padding max_selling_col_width selling ^ yellowify selling
  in
  let buying = string_of_float buying in
  let buying = make_padding max_buying_col_width buying ^ blueify buying in
  [currency; selling; buying] |> join "\t" |> print_endline

let () =
  let body = Lwt_main.run body in
  let body = Yojson.Basic.Util.to_list body in
  let body = List.map parse_currency body in
  let body = body |> List.sort (fun a b -> -compare a.selling b.selling) in
  let max_currency_col_width =
    List.fold_left
      (fun acc currency -> max acc (String.length currency.currency))
      0 body
  in
  let max_selling_col_width =
    List.fold_left
      (fun acc currency ->
        max acc (String.length (string_of_float currency.selling)) )
      0 body
  in
  let max_buying_col_width =
    List.fold_left
      (fun acc currency ->
        max acc (String.length (string_of_float currency.buying)) )
      0 body
  in
  let currency = "Currency" in
  let selling = "Selling" in
  let buying = "Buying" in
  let currency_padding = make_padding max_currency_col_width currency in
  let selling_padding = make_padding max_selling_col_width selling in
  let buying_padding = make_padding max_buying_col_width buying in
  let header =
    [ greenify currency ^ currency_padding
    ; selling_padding ^ yellowify selling
    ; buying_padding ^ blueify buying ]
    |> join "\t"
  in
  let () = print_endline header in
  let () = print_endline "" in
  body
  |> List.iter
       (print_currency
          (max_currency_col_width, max_selling_col_width, max_buying_col_width) )
