import Combine
import Models
import Services
import SwiftUI
import Views

final class LabelsViewModel: ObservableObject {
  private var hasLoadedInitialLabels = false
  @Published var isLoading = false
  @Published var selectedLabelsForItemInContext = [FeedItemLabel]()
  @Published var unselectedLabelsForItemInContext = [FeedItemLabel]()
  @Published var labels = [FeedItemLabel]()
  @Published var showCreateEmailModal = false

  var subscriptions = Set<AnyCancellable>()

  func loadLabels(dataService: DataService, item: FeedItem?) {
    guard !hasLoadedInitialLabels else { return }
    isLoading = true

    dataService.labelsPublisher().sink(
      receiveCompletion: { _ in },
      receiveValue: { [weak self] allLabels in
        self?.isLoading = false
        self?.labels = allLabels
        self?.hasLoadedInitialLabels = true
        if let item = item {
          self?.selectedLabelsForItemInContext = item.labels
          self?.unselectedLabelsForItemInContext = allLabels.filter { label in
            !item.labels.contains(where: { $0.id == label.id })
          }
        }
      }
    )
    .store(in: &subscriptions)
  }

  func createLabel(dataService: DataService, name: String, color: Color, description: String?) {
    isLoading = true

    dataService.createLabelPublisher(
      name: name,
      color: color.hex ?? "",
      description: description
    ).sink(
      receiveCompletion: { [weak self] _ in
        self?.isLoading = false
      },
      receiveValue: { [weak self] result in
        self?.isLoading = false
        self?.labels.insert(result, at: 0)
        self?.unselectedLabelsForItemInContext.insert(result, at: 0)
        self?.showCreateEmailModal = false
      }
    )
    .store(in: &subscriptions)
  }

  func deleteLabel(dataService: DataService, labelID: String) {
    isLoading = true

    dataService.removeLabelPublisher(labelID: labelID).sink(
      receiveCompletion: { [weak self] _ in
        self?.isLoading = false
      },
      receiveValue: { [weak self] _ in
        self?.isLoading = false
        self?.labels.removeAll { $0.id == labelID }
      }
    )
    .store(in: &subscriptions)
  }

  func saveItemLabelChanges(itemID: String, dataService: DataService, onComplete: @escaping ([FeedItemLabel]) -> Void) {
    isLoading = true
    dataService.updateArticleLabelsPublisher(itemID: itemID, labelIDs: selectedLabelsForItemInContext.map(\.id)).sink(
      receiveCompletion: { [weak self] _ in
        self?.isLoading = false
      },
      receiveValue: { onComplete($0) }
    )
    .store(in: &subscriptions)
  }

  func addLabelToItem(_ label: FeedItemLabel) {
    selectedLabelsForItemInContext.insert(label, at: 0)
    unselectedLabelsForItemInContext.removeAll { $0.id == label.id }
  }

  func removeLabelFromItem(_ label: FeedItemLabel) {
    unselectedLabelsForItemInContext.insert(label, at: 0)
    selectedLabelsForItemInContext.removeAll { $0.id == label.id }
  }
}