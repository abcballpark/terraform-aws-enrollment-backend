const TABLE_NAME = "Participant";

const { createRecord } = require("../dynamodb");


const create = async (item) => {
  await createRecord(TABLE_NAME, item);
};


module.exports = {
  create,
};
