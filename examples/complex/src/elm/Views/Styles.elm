module Views.Styles exposing (..)

import Color exposing (rgb, rgba)
import Style exposing (..)
import Style.Color as Color
import Style.Background as Background
import Style.Border as Border
import Style.Font as Font
import Style.Filter as Filter
import Style.Shadow as Shadow
import Style.Transition as Transition


type Styles
    = None
    | Button
    | Header
    | WidgetSummary
    | WidgetConfirm
    | WidgetText
    | ProfileImage
    | Sidebar
    | Status
    | StatusSuccess
    | StatusFailure
    | StatusAlert
      --Login
    | LoginBox
    | LoginPage
      -- Modal
    | ModalBox
    | ModalBoxSelection
    | ModalBoxSelectionMultiline
    | BreadcrumbItem
    | BreadcrumbItemWrapper


type Variations
    = H2
    | H3
    | H4
    | Small
    | Bold
    | Selected
    | Shadowed
    | FirstItem
    | LastItem
    | LastItemSelected
    | WidgetBlue
    | WidgetWhite


stylesheet : StyleSheet Styles Variations
stylesheet =
    let
        fontSourceSans =
            Font.typeface
                [ Font.font "Source Sans Pro", Font.sansSerif ]

        textGray =
            rgb 112 112 112

        widgetGray =
            rgb 64 64 64

        widgetGrayOpacity a =
            rgba 64 64 64 a

        widgetOrange =
            rgb 245 132 33

        widgetBlue =
            rgb 0 122 255

        widgetRed =
            rgb 226 64 54

        widgetLightGray =
            rgb 171 180 189

        widgetGreen =
            rgb 116 203 52
    in
        Style.styleSheet
            [ style None []
            , style Button
                [ Border.all 1
                , Border.rounded 4
                , Color.border widgetGray
                , Color.background widgetGray
                , Color.text Color.white
                , fontSourceSans
                , hover
                    [ Color.background <| widgetGrayOpacity 0.8
                    , Color.border <| widgetGrayOpacity 0.8
                    , Style.cursor "pointer"
                    ]
                ]
            , style Header
                [ fontSourceSans
                , Color.text widgetGray
                , Font.weight 75
                , variation H2 [ Font.size 30 ]
                , variation H3 [ Font.size 25 ]
                , variation H4 [ Font.size 20 ]
                , variation Bold [ Font.bold ]
                , variation WidgetBlue [ Color.text widgetBlue ]
                , variation WidgetWhite [ Color.text Color.white ]
                ]
            , style WidgetSummary
                [ Border.all 1
                , Border.rounded 30
                , Color.border textGray
                , Transition.all
                , Shadow.deep
                , hover
                    [ Shadow.simple ]
                ]
            , style WidgetConfirm
                [ Border.all 1
                , Border.rounded 20
                , Color.border textGray
                ]
            , style WidgetText
                [ fontSourceSans
                , Font.weight 2
                , Font.size 16
                , Font.light
                , variation Bold [ Font.bold ]
                , variation Small [ Font.size 13 ]
                , variation WidgetBlue [ Color.text widgetBlue ]
                , variation WidgetWhite [ Color.text Color.white ]
                ]
            , style ProfileImage
                [ Border.all 3
                , Color.border widgetLightGray
                , Color.background Color.white
                ]
            , style Sidebar
                [ Border.right 1
                , Color.border Color.black
                , Color.background widgetGray
                , Shadow.box
                    { offset = ( 0, 0 )
                    , size = 1
                    , blur = 2
                    , color = widgetLightGray
                    }
                ]
            , style Status
                [ fontSourceSans
                , Color.text Color.white
                ]
            , style StatusSuccess
                [ Color.background Color.green ]
            , style StatusFailure
                [ Color.background Color.red ]
            , style StatusAlert
                [ Color.background Color.orange ]
            , style LoginBox
                [ fontSourceSans
                , Color.background <| widgetGrayOpacity 0.8
                , Color.text Color.white
                , Border.rounded 5
                , Font.size 20
                , Shadow.box
                    { offset = ( 0, 0 )
                    , size = 3
                    , blur = 10
                    , color = rgba 240 240 240 0.2
                    }
                , hover [ Style.cursor "pointer" ]
                ]
            , style LoginPage
                [ Background.imageWith
                    { src = "static/img/potter-bw.jpg"
                    , position = ( 0, 0 )
                    , repeat = Background.noRepeat
                    , size = Background.cover
                    }
                ]
            , style ModalBox
                [ Border.rounded 5
                , Border.all 1
                , Color.background Color.white
                , Color.border widgetLightGray
                ]
            , style ModalBoxSelection
                [ Border.bottom 1
                , Color.border widgetLightGray
                , focus [ Color.border widgetBlue ]
                ]
            , style ModalBoxSelectionMultiline
                [ Border.all 1
                , Color.border widgetLightGray
                , focus [ Color.border widgetBlue ]
                ]
            , style BreadcrumbItem
                [ Color.background Color.darkGrey
                , Border.roundTopRight 100
                , Border.roundBottomRight 100
                , Color.text Color.white
                , Style.cursor "pointer"
                , variation Shadowed [ Shadow.drop { offset = ( 5, 0 ), blur = 5, color = widgetGrayOpacity 0.2 } ]
                , variation FirstItem [ Border.roundTopLeft 100, Border.roundBottomLeft 100 ]
                , variation Selected [ Color.text widgetBlue, Color.background Color.white ]
                , variation LastItemSelected [ Color.background widgetGreen ]
                , Font.size 13
                , fontSourceSans
                ]
            , style BreadcrumbItemWrapper
                [ Color.background Color.darkGrey
                , variation Selected [ Color.background Color.white ]
                , variation FirstItem [ Border.roundTopLeft 100, Border.roundBottomLeft 100 ]
                , variation LastItem [ Border.roundTopRight 100, Border.roundBottomRight 100 ]
                , variation LastItemSelected [ Color.background widgetGreen ]
                ]
            ]
