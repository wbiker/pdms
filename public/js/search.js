$('documnet').ready(function() {
  $('#search_tb').textbox({
    buttonText: 'Search',
    iconCls: 'icon-search',
    iconAlign: 'left',
    prompt: 'tag:<tag> category:<category>',
    onClickButton: function() {
      console.log("button clicked");
      var text_str = $(this).textbox('getText');
      if(text_str == "") {
        $(this).textbox('setText', "No search text given");
      }
      else {
        var sendData = { text: text_str };
        $.get('get_files', sendData, function(data) {
          console.log("Answer from server: " + JSON.stringify(data));

        }).fail(function(xqXHR) {
          console.log("Error: " + JSON.stringify(xqXHR));
        });
      }
    }
  });

  $('#result_table').datagrid({
    url: 'get_files',
    method: 'GET',
    columns: [[
      {field:'name',title:'Name',width:300},
      {field:'category.name',title:'Category',formatter: function(value,row) { return row.category.name}}
    ]]
  });

  //$.get('get_files', {}, function(data_send) {
  //  console.log("Got data: " + JSON.stringify(data_send));
  //  $('#result_table').datagrid({
  //    data: data_send
  //  });
  //}).fail(function(error) {
  //  console.log("Error: " + JSON.stringify(error));
  //});
});
