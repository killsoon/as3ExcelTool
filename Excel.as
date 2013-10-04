package com.lipi.excel
{
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	/**
	 * 解析excel（xlsx)文件的类
	 */
	public class Excel
	{
		private var _fileByteArray:ByteArray;
		private var _sheetDic:Dictionary;
		private var _zip:Zip;
		
		/**
		 * 
		 * @param fileByteArray xlsx文件的二进制数据
		 * @param sheetIndex excel表索引，对应excel中的工作表的标签，索引从0开始
		 */
		public function Excel(fileByteArray:ByteArray)
		{
			_fileByteArray = fileByteArray;
		}
		
		/**
		 * 取得解析后的表格数据。值为二维数组，第一维是行索引，第二维是列索引
		 */
		public function getSheetDic():Dictionary
		{
			if (_sheetDic)
				return _sheetDic;
			else
				_sheetDic = new Dictionary();
			
			_zip = new Zip(_fileByteArray);
			
			var returnSheetDic:Dictionary = new Dictionary();
			var valueArray:Array = getValueArray(); 
			
			var excelSheetDic:Dictionary = _zip.getSheetDataDic();
			for (var key:String in excelSheetDic)
			{
				var $byteArray:ByteArray = excelSheetDic[key];
				var xmlString:String = $byteArray.readUTFBytes($byteArray.bytesAvailable);
				var $xml:XML = new XML(xmlString);
				var ns:Namespace = $xml.namespace();
				
				var excelArray:Array = [];
				var rowList:XMLList = $xml.ns::sheetData.ns::row;
				for each(var rowListItem:XML in rowList)
				{
					var rowIndex:int = int(rowListItem.@r) - 1;
					var rowArray:Array = [];
					var colList:XMLList = rowListItem.ns::c;
					for each(var colListItem:XML in colList)
					{
						var colIndex:int = ExcelUtil.getColIndex(colListItem.@r);
						var t:String = colListItem.@t;
						var v:String = colListItem.ns::v[0];
						if(t == "s")
						{
							rowArray[colIndex] = valueArray[int(v)];
						}else{
							rowArray[colIndex] = v;
						}
					}
					excelArray[rowIndex] = rowArray;
				}
				
				var mergeCellList:XMLList = $xml.ns::mergeCells.ns::mergeCell;
				for each(var mergeCellXML:XML in mergeCellList)
				{
					var ref:String = mergeCellXML.@ref;
					var refArr:Array = ref.split(":");
					var sArr:Array = ExcelUtil.colNameToPosition(refArr[0]);
					var eArr:Array = ExcelUtil.colNameToPosition(refArr[1]);
					var sValue:Object;
					if(excelArray[sArr[0]] != null)
					{
						sValue = excelArray[sArr[0]][sArr[1]];
					}
					for(var i:int = sArr[0];i<=eArr[0];i++)
					{
						for(var j:int = sArr[1];j<=eArr[1];j++)
						{
							if(excelArray[i] == null) excelArray[i] = [];
							excelArray[i][j] = sValue;
						}
					}
					
				}
				_sheetDic[key] = excelArray;
			}
			
			
			return _sheetDic;
		}
		
		
		private function getValueArray():Array
		{
			var valueArray:Array = [];
			var $url:String = "xl/sharedStrings.xml";
			
			var $byteArray:ByteArray = _zip.getFile($url);
			$byteArray.position = 0;
			var xmlString:String = $byteArray.readUTFBytes($byteArray.bytesAvailable);
			
			var $xml:XML = new XML(xmlString);
			var ns:Namespace = $xml.namespace();
			
			var valueList:XMLList = $xml.ns::si;
			for each(var valueListItem:XML in valueList)
			{
				var textList:XMLList = valueListItem..ns::t;
				var tValue:String = "";
				for each(var textListItem:XML in textList)
				{
					var $cTValue:String = textListItem[0];
					tValue = tValue + $cTValue;
				}
				
				valueArray.push(tValue);
			}
			return valueArray;
		}
		
		
		
		
		
		
	}
}