module KOLC exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Element
import Collage
import Random
import Http
import Json.Decode as Decode exposing (Decoder, field, succeed)
import Json.Encode as Encode

--decoders
decoderDamage : Decoder AdventureResult
decoderDamage =
  Decode.map3 AdventureResult
    (field "damage" Decode.int)
    (field "name" Decode.string)
    (field "location" Decode.string)

decoderTurnDamage : Decoder Int
decoderTurnDamage =
  field "damage" Decode.int

type alias Model =
  { equipped : Bool
  , allitems : List String
  , adventures: Int
  , mode: Mode
  , currency: Int
  , hitpoints: Int
  }

type alias AdventureResult =
  {damage : Int
  , name : String
  , location: String
  }

type Mode = Combat String Loc Int | Noncombat Loc

type Msg = NewGame | Equip | Rollover | Rest | SelectLoc Loc | AdventureLoc Loc
         | DealDamage String
         | Damage (Result Http.Error AdventureResult) | TurnDamage (Result Http.Error Int)
type Loc = Main | Inventory | Beach | Forest | Town

initialModel : Model
initialModel =
  { equipped = False
  , allitems = ["beans", "muffin", "overalls", "cool hat"]
  , adventures = 40
  , mode = Noncombat Main
  , currency = 0
  , hitpoints = 10
  }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of

    NewGame ->
      ( initialModel, Cmd.none )
    Equip ->
      ( { model | equipped = True }, Cmd.none )
    Rollover ->
      ( { model | adventures = capAdventures (model.adventures + 40) }, Cmd.none )
    Rest ->
      ( { model | adventures = model.adventures - 1, hitpoints = model.hitpoints + 10}, Cmd.none )
    SelectLoc loc ->
      ( { model | mode = Noncombat loc }, Cmd.none )
    AdventureLoc loc ->
      ( { model
        | adventures = model.adventures - 1
        , currency = capCurrency (model.currency + 5)
        }, takeDamage loc)
    DealDamage name ->
      if isMonsterDead model.mode then
        ( { model | mode = Noncombat (locFromMode model.mode) }, Cmd.none )
      else
        ( { model | mode = playerDoesDamage model.mode }, takeTurnDamage name 1 )
    Damage (Ok adv) ->
      ( { model |
          hitpoints = capHitpoints (model.hitpoints - adv.damage),
          mode = startFightWith model.mode adv.name
          --name = adv.name,
          --location = adv.location
         }, Cmd.none )
    Damage (Err error) ->
      let
        _ = Debug.log "Oops!" error
      in
        (model, Cmd.none)
    TurnDamage (Ok hp) ->
      ( { model | hitpoints = capHitpoints (model.hitpoints - hp) }, Cmd.none )
    TurnDamage (Err error) ->
      let
        _ = Debug.log "Oops TurnDamage failed" error
      in
        (model, Cmd.none)



-- commands

takeDamage : Loc -> Cmd Msg
takeDamage loc =
  --Random.generate Damage (Random.int 1 10)
  (decoderDamage)
    |> Http.post damageUrl (makeBody (makeValue loc))
    |> Http.send Damage

--
damageUrl : String
damageUrl =
  "http://localhost:8000/advs/"

makeValue : Loc -> Encode.Value
makeValue loc =
  let
    locstring = toString loc
  in
    Encode.object
      [ ("current_loc", Encode.string locstring) ]


makeBody : Encode.Value -> Http.Body
makeBody value =
  Http.stringBody "application/json" (Encode.encode 0 value)

takeTurnDamage : String -> Int -> Cmd Msg
takeTurnDamage name hp =
  (decoderTurnDamage)
    |> Http.post "http://localhost:8000/advs/turn_damage" (makeBody (Encode.object [ ("name", Encode.string name) ]))
    |> Http.send TurnDamage



capAdventures : Int -> Int
capAdventures previous =
  if previous >= 200 then 200
  else previous

capHitpoints: Int -> Int
capHitpoints previous =
  if previous < 0 then 0
  else previous

capCurrency: Int -> Int
capCurrency previous =
  if previous < 0 then 0
  else previous

locFromMode : Mode -> Loc
locFromMode mode =
  case mode of
    Combat who loc hp ->
      loc
    Noncombat loc ->
      loc

isMonsterDead : Mode -> Bool
isMonsterDead m =
  case m of
    Combat who location_name hp ->
      if hp == 1 then True
      else False
    Noncombat loc ->
      let
        _ = Debug.log "Oops! unexpected Noncombat mode?"
      in
        True

playerDoesDamage : Mode -> Mode
playerDoesDamage m =
  case m of
    Combat who location_name hp ->
      Combat who location_name (hp - 1)
    Noncombat loc ->
      let
        _ = Debug.log "Oops! unexpected Noncombat mode?"
      in
        Noncombat loc

startFightWith : Mode -> String -> Mode
startFightWith m who =
  case m of
    Combat who loc hp ->
      let
        _ = Debug.log "Oops! unexpected combat?"
      in
        Combat who loc hp
    Noncombat loc ->
      Combat who loc 3 --TODO get initial hp from backend here


viewCharacter : Model -> Html Msg
viewCharacter model =
  (Element.toHtml ( Collage.collage 60 100
    ([ Collage.toForm ( Element.image 60 100 "/static/advs/img/base.gif" ) ]
    ++
      (if model.equipped then
        [ Collage.toForm ( Element.image 60 100 "/static/advs/img/hat.gif" ) ]
      else
        [] )
      )
    )
  )

viewMode : Model -> Html Msg
viewMode model =
  case model.mode of
    Combat name location hp ->
      div []
        [ p [ ] [text ("Monster Name: " ++ name)]
        , p [ ] [text (" Monster HP: " ++ (toString hp))]
        , div [ class "button-group"]
              [ button [ onClick (TurnDamage (Ok 3)) ] [ text "Taunt Tonald"]
              , button [ onClick (DealDamage name) ] [ text "Hit it with your fists" ]
              , button [ ] [ text "Run away" ]
              ]
        ]
    Noncombat loc ->
      case loc of
        Main ->
          div [ ]
              [ img [src "/static/advs/img/place1.gif", onClick (SelectLoc Beach) ] [ ]
              , img [src "/static/advs/img/place3.gif", onClick (SelectLoc Forest) ] [ ]
              , img [src "/static/advs/img/place2.gif", onClick (SelectLoc Town) ] [ ]
              ]
        Inventory ->
          ul []
            (List.map (\l -> li [] [ text l, img [src "/static/advs/img/place1.gif"] [] ]) model.allitems)
        Beach ->
          div [ ]
              [ img [src "/static/advs/img/place1.gif", onClick (AdventureLoc Beach) ] [ ]
              ]
        Forest ->
          div [ ]
              [ img [src "/static/advs/img/place3.gif", onClick (AdventureLoc Forest) ] [ ]
              ]
        Town ->
          div [ ]
              [ img [src "/static/advs/img/place2.gif", onClick (AdventureLoc Town) ] [ ]
              ]


view : Model -> Html Msg
view model =
  div []
  [ div [ class "char-pane" ]
        [ viewCharacter model
        , p [ ] [text (" Hitpoints: " ++ (toString model.hitpoints))]
        , p [ ] [text (" Currency: " ++ (toString model.currency))]
        , p [ ] [text (" Adventures: " ++ (toString model.adventures))]

        ]
  , div [ class "button-group", class "nav-pane"]
      [ button [ onClick (SelectLoc Main) ] [ text "Main Map"]
      , button [ onClick (SelectLoc Inventory) ] [ text "Inventory"]
      , button [ onClick Equip ] [ text "Equip that Shit"]
      , button [ onClick Rollover ] [ text "New Day"]
      , button [ onClick Rest ] [ text "Rest"]
      ]
  , viewMode model

  ]

main : Program Never Model Msg
main =
  Html.program
  { init = ( initialModel, Cmd.none )
  , view = view
  , update = update
  , subscriptions = (\model -> Sub.none)
  }
