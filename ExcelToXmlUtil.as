package
{
	public class ExcelToXmlUtil
	{
		static public function excelToXml(dataArray:Array):XML
		{
			var returnXml:XML = <config />;
			
			var row:int = dataArray.length;
			for (var i:int = 2; i < row; i++)
			{
				var itemXml:XML = <item />;
				if (dataArray[i] == null)
					continue;
				var column:int = dataArray[i].length;
				for (var k:int = 0; k < column; k++)
					itemXml.@[dataArray[1][k]] = dataArray[i][k];
				returnXml.appendChild(itemXml);
			}
			return returnXml;
		}
	}
}