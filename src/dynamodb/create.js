const AWS = require('aws-sdk');

module.exports = async (tableName, item) => {
  const dynamodb = new AWS.DynamoDB({apiVersion: '2012-08-10'});

  // Convert to DynamodDB record format
  const record = AWS.DynamoDB.Converter.marshall(item);

  // Call DynamoDB to add the item to the table
  await ddb.putItem({
    TableName: tableName,
    Item: record,
  }).promise();
};
