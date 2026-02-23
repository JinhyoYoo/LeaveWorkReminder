import Foundation

final class XMLParsingService: NSObject, XMLParserDelegate, @unchecked Sendable {

    private var items: [[String: String]] = []
    private var currentElement: String = ""
    private var currentItem: [String: String] = [:]
    private var isInsideItem = false
    private let itemElementName: String

    init(itemElementName: String = "itemList") {
        self.itemElementName = itemElementName
    }

    func parse(data: Data) -> [[String: String]] {
        items = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return items
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        if elementName == itemElementName {
            isInsideItem = true
            currentItem = [:]
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isInsideItem else { return }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let existing = currentItem[currentElement] {
            currentItem[currentElement] = existing + trimmed
        } else {
            currentItem[currentElement] = trimmed
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == itemElementName {
            isInsideItem = false
            items.append(currentItem)
        }
    }
}
