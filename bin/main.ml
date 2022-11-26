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

let () =
  let body = Lwt_main.run body in
  let body = Yojson.Basic.Util.to_list body in
  let body = List.map parse_currency body in
  let max_currency_col_width =
    List.fold_left
      (fun acc currency -> max acc (String.length currency.currency))
      0 body
  in
  let _ =
    List.fold_left
      (fun acc currency ->
        max acc (String.length (string_of_float currency.selling)) )
      0 body
  in
  let _ =
    List.fold_left
      (fun acc currency ->
        max acc (String.length (string_of_float currency.buying)) )
      0 body
  in
  let () = print_endline "" in
  let currency = "Currency" in
  let selling = "Selling" in
  let buying = "Buying" in
  let currency_padding =
    String.make (max_currency_col_width - String.length currency) ' '
  in
  let selling_padding =
    String.make (max_currency_col_width - String.length selling) ' '
  in
  let buying_padding =
    String.make (max_currency_col_width - String.length buying) ' '
  in
  let () =
    print_endline
      ( "| "  ^ currency ^ currency_padding ^ " | " ^ selling_padding ^ selling
      ^ " | " ^ buying_padding ^ buying ^ " | " )
  in
  body
  |> List.iter (fun {selling; buying; currency} ->
         let padding =
           String.make (max_currency_col_width - String.length currency) ' '
         in
         let currency = "| " ^ currency ^ padding ^ " | " in
         let selling = string_of_float selling in
         let padding =
           String.make (max_currency_col_width - String.length selling) ' '
         in
         let selling = padding ^ selling ^ " | " in
         let buying = string_of_float buying in
         let padding =
           String.make (max_currency_col_width - String.length buying) ' '
         in
         let buying = padding ^ buying ^ " |" in
         let row = currency ^ selling ^ buying in
         print_endline row )
