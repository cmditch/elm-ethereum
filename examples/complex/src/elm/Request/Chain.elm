module Request.Chain exposing (..)

-- Library

import Eth as Eth
import Eth.Types as Eth
import Task exposing (Task)
import Http


-- Internal

import Extra.BigInt exposing (countDownFrom)
import Contracts.WidgetFactory as Widget exposing (Widget)


getWidgetList : Eth.HttpProvider -> Eth.Address -> Task Http.Error (List Widget)
getWidgetList ethNode widgetFactory =
    Eth.call ethNode (Widget.widgetCount widgetFactory)
        |> Task.andThen
            (\num ->
                countDownFrom num
                    |> List.map
                        (\id -> Eth.call ethNode (Widget.widgets widgetFactory id))
                    |> Task.sequence
            )
