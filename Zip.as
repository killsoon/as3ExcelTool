package com.lipi.excel
{
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;

	/**
	 * 对Zip文件进行解码
	 */
	public class Zip
	{
		private var _zipFile:ByteArray;
		private var _fileDic:Object;
		private var _fileInflateMark:Object;
		
		
		/**
		 * @param zipFile zip文件的二进制数据
		 * 
		 */
		public function Zip(zipFile:ByteArray = null)
		{
			_fileDic = {};
			_fileInflateMark = {};
			_zipFile = zipFile;
			parse();
		}
		
		/**
		 * 增加文件到zip实例，此方法为new Zip(zipFile)的替代方法。
		 * 如果多次调用此方法,zipFile中相同文件名的文件将被复盖
		 * @param zipFile zip文件的二进制数据
		 */
		public function addZipFile(zipFile:ByteArray):void
		{
			_zipFile = zipFile;
			parse();
		}
		
		
		private function parse():void
		{
			if(_zipFile == null) return;
			_zipFile.endian = Endian.LITTLE_ENDIAN;
			_zipFile.position = 0;
			
			while(true)
			{
				var headValue:int = _zipFile.readUnsignedInt();
				if(headValue != 0x04034b50)
				{
					break;
				}
				_zipFile.position = _zipFile.position + 14;
				var compressSize:int = _zipFile.readUnsignedInt();
				var uncompressSize:int = _zipFile.readUnsignedInt();
				var fileNameLength:int = _zipFile.readUnsignedShort();
				var otherLength:int = _zipFile.readUnsignedShort();
				var fileName:String = _zipFile.readUTFBytes(fileNameLength);
				_zipFile.position = _zipFile.position + otherLength;
				var fileByteArray:ByteArray = new ByteArray();
				_zipFile.readBytes(fileByteArray,0,compressSize);
				_fileDic[fileName] = fileByteArray;
			}
		}
		
		/**
		 * 获取配置表字典
		 * @return
		 */
		public function getSheetDataDic():Dictionary
		{
			var sheetDic:Dictionary = new Dictionary();
			var workbookByteArray:ByteArray = _fileDic["xl/workbook.xml"];
			workbookByteArray.position = 0;
			workbookByteArray.inflate();
			var workbook:XML = new XML(workbookByteArray);
			var ns:Namespace = workbook.namespace();
			
			var sheetXmlList:XMLList = workbook.ns::sheets.ns::sheet;
			for (var i:int = 0; i < sheetXmlList.length(); i++)
			{
				var sheetStr:String = sheetXmlList[i].toXMLString();
				var sheetArr:Array = sheetStr.split("\"");
				var sheetName:String = sheetArr[1];
				var sheetId:String = sheetArr[5].toString().slice(3);
				var fileName:String = "xl/worksheets/sheet" + sheetId + ".xml";
				
				var $fileByteArray:ByteArray = _fileDic[fileName];
				if(_fileInflateMark[fileName] != true)
				{
					$fileByteArray.position = 0;
					$fileByteArray.inflate();
					_fileInflateMark[fileName] = true;
				}
				sheetDic[sheetName] = $fileByteArray;
			}
			return sheetDic;
		}
		
		/**
		 * 通过文件名取得解压缩后的文件的二进制数据
		 * @param fileName 文件名
		 * @return 文件的二进制数据
		 */
		public function getFile(fileName:String):ByteArray
		{
//			xl/worksheets/sheet" + 3 + ".xml
			var $fileByteArray:ByteArray = _fileDic[fileName];
			if(_fileInflateMark[fileName] != true)
			{
				$fileByteArray.position = 0;
				$fileByteArray.inflate();
				_fileInflateMark[fileName] = true;
			}
			return $fileByteArray;
		}
		
		/**
		 * 取得zip中的文件名的列表
		 * @return 
		 * 
		 */
		public function getFileNameList():Array
		{
			var $fileNameList:Array = [];
			for(var name:String in _fileDic)
			{
				$fileNameList.push(name);
			}
			return $fileNameList;
		}
		
		
		
		
	}
}