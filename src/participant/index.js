const { create } = require("./participant");

module.exports = async (event, context, callback) => {
  const item = JSON.parse(event.body);
  let result;
  switch (event.httpMethod) {
    case "POST":
      result = await create(item);
      break;
  
    default:
      break;
  }
  callback(null, result);
};
