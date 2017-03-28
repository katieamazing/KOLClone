module KOLC exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Element
import Collage
import Random
import Http
import Json.Decode as Decode exposing (Decoder, field, succeed)

--decoders
decoderDamage : Decoder AdventureResult
decoderDamage =
  Decode.map2 AdventureResult
    (field "damage" Decode.int)
    (field "name" Decode.string)

type alias Model =
  { equipped : Bool
  , adventures: Int
  , selected: Loc
  , name: String
  , currency: Int
  , hitpoints: Int
  }

type alias AdventureResult =
  {damage : Int
  , name : String
  }

type Msg = NewGame | Equip | Rollover | Rest | SelectLoc Loc | AdventureLoc Loc
         | Damage (Result Http.Error AdventureResult)
type Loc = Main | Beach | Forest | Town

initialModel : Model
initialModel =
  { equipped = False
  , adventures = 40
  , selected = Main
  , name = ""
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
      ( { model | selected = loc }, Cmd.none )
    AdventureLoc loc ->
      ( { model
        | adventures = model.adventures - 1
        , currency = capCurrency (model.currency + 5)
        }, takeDamage )
    Damage (Ok adv) ->
      ( { model |
          hitpoints = capHitpoints (model.hitpoints - adv.damage),
          name = adv.name
         }, Cmd.none )
    Damage (Err error) ->
      let
        _ = Debug.log "Oops!" error
      in
        (model, Cmd.none)


-- commands

takeDamage : Cmd Msg
takeDamage =
  --Random.generate Damage (Random.int 1 10)
  (decoderDamage)
    |> Http.get damageUrl
    |> Http.send Damage

--
damageUrl : String
damageUrl =
  "http://localhost:8000/advs"

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

viewCharacter : Model -> Html Msg
viewCharacter model =
  (Element.toHtml ( Collage.collage 60 100
    ([ Collage.toForm ( Element.image 60 100 "img/base.gif" ) ]
    ++
      (if model.equipped then
        [ Collage.toForm ( Element.image 60 100 "img/hat.gif" ) ]
      else
        [] )
      )
    )
  )

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
      , button [ onClick Equip ] [ text "Equip that Shit"]
      , button [ onClick Rollover ] [ text "New Day"]
      , button [ onClick Rest ] [ text "Rest"]
      ]
  , viewMap model
  , p [ ] [text ("Current Adventure: " ++ model.name)]
  ]

viewMap : Model -> Html Msg
viewMap model =
  case model.selected of
    Main ->
      div [ ]
          [ img [src "img/place1.gif", onClick (SelectLoc Beach) ] [ ]
          , img [src "img/place3.gif", onClick (SelectLoc Forest) ] [ ]
          , img [src "img/place2.gif", onClick (SelectLoc Town) ] [ ]
          ]
    Beach ->
      div [ ]
          [ img [src "img/place1.gif", onClick (AdventureLoc Beach) ] [ ]
          ]
    Forest ->
      div [ ]
          [ img [src "img/place3.gif", onClick (AdventureLoc Forest) ] [ ]
          ]
    Town ->
      div [ ]
          [ img [src "img/place2.gif", onClick (AdventureLoc Town) ] [ ]
          ]


main : Program Never Model Msg
main =
  Html.program
  { init = ( initialModel, Cmd.none )
  , view = view
  , update = update
  , subscriptions = (\model -> Sub.none)
  }