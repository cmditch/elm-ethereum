module Views.Helpers exposing (..)

-- Libraries

import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import List.Extra as List
import SelectList as SL exposing (SelectList)


-- Internal

import Views.Styles exposing (..)
import Eth.Types exposing (Address)
import Eth.Utils exposing (addressToString)


etherscanLink : Address -> Element Styles Variations msg
etherscanLink address =
    let
        address_ =
            addressToString address
    in
        newTab ("https://ropsten.etherscan.io/address/" ++ address_) <|
            underline (String.left 5 address_ ++ "..." ++ String.right 5 address_)


viewBreadcrumbs : (formStep -> String) -> (formStep -> msg) -> formStep -> SelectList formStep -> Element Styles Variations msg
viewBreadcrumbs stepToString changeStep lastStep steps =
    let
        stepsList =
            SL.toList steps

        selected =
            SL.selected steps

        lastIndex =
            (List.length stepsList) - 1

        previousStep step =
            SL.before steps
                |> List.last
                |> Maybe.map ((==) step)
                |> Maybe.withDefault False

        -- First items in the list have the highest z-index
        viewCrumb index step =
            el BreadcrumbItemWrapper
                [ vary Selected (previousStep step)
                , vary LastItemSelected (index == lastIndex - 1 && lastStep == selected)
                , vary LastItem (index == lastIndex)
                , vary FirstItem (index == 0)
                , inlineStyle [ ( "z-index", toString (30 - index) ) ]
                ]
                (el BreadcrumbItem
                    [ paddingXY 15 10.1
                    , inlineStyle [ ( "z-index", toString (30 - index) ) ]
                    , vary Shadowed (index /= lastIndex)
                    , vary Selected (step == selected && index /= lastIndex)
                    , vary FirstItem (index == 0)
                    , vary LastItemSelected (index == lastIndex && lastStep == selected)
                    , onClick <| changeStep step
                    ]
                    (text <| stepToString step)
                )
    in
        row None [] (List.indexedMap viewCrumb stepsList)
