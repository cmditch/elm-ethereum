pragma solidity 0.4.24;

contract WidgetFactory {

    event WidgetCreated(uint id, uint size, uint cost, address owner);
    event WidgetSold(uint id);

    struct Widget {
        uint id;
        uint size;
        uint cost;
        address owner;
        bool wasSold;
    }

    Widget[] public widgets;

    function newWidget(uint size_, uint cost_, address owner_) public {
        uint id = widgets.length;
        widgets.push(Widget(id, size_, cost_, owner_, false));
        emit WidgetCreated(id, size_, cost_, owner_);
    }

    function sellWidget(uint id_) public {
        Widget storage widget = widgets[id_];
        widget.wasSold = true;
        emit WidgetSold(id_);
    }

    function widgetCount() public view returns(uint) {
        return widgets.length;
    }
}