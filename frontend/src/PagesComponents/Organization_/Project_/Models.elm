module PagesComponents.Organization_.Project_.Models exposing (AmlSidebar, AmlSidebarMsg(..), ConfirmDialog, ContextMenu, FindPathMsg(..), GroupEdit, GroupMsg(..), HelpDialog, HelpMsg(..), LayoutMsg(..), LinkMsg(..), MemoEdit, MemoMsg(..), ModalDialog, Model, Msg(..), NavbarModel, NotesDialog, ProjectSettingsDialog, ProjectSettingsMsg(..), PromptDialog, SchemaAnalysisDialog, SchemaAnalysisMsg(..), SearchModel, VirtualRelation, VirtualRelationMsg(..), confirm, confirmDanger, emptyModel, prompt, promptSelect, simplePrompt, simplePromptSelect)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Organisms.Table exposing (TableHover)
import Components.Organisms.TableRow as TableRow exposing (TableRowHover)
import Components.Slices.DataExplorer as DataExplorer
import Components.Slices.PlanDialog as PlanDialog
import DataSources.DbMiner.DbTypes exposing (RowQuery)
import DataSources.JsonMiner.JsonSchema exposing (JsonSchema)
import Dict exposing (Dict)
import Html exposing (Html, text)
import Libs.Html.Events exposing (PointerEvent, WheelEvent)
import Libs.Models exposing (ZoomDelta)
import Libs.Models.Delta exposing (Delta)
import Libs.Models.DragId exposing (DragId)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Notes exposing (Notes)
import Libs.Tailwind as Tw exposing (Color)
import Libs.Task as T
import Models.AutoLayout exposing (AutoLayoutMethod)
import Models.ColumnOrder exposing (ColumnOrder)
import Models.ErdProps as ErdProps exposing (ErdProps)
import Models.OpenAIKey exposing (OpenAIKey)
import Models.OpenAIModel exposing (OpenAIModel)
import Models.Organization exposing (Organization)
import Models.ParserError exposing (ParserError)
import Models.Position as Position
import Models.Project.CanvasProps exposing (CanvasProps)
import Models.Project.ColumnId exposing (ColumnId)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.ColumnStats exposing (ColumnStats)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.Group exposing (Group)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.ProjectStorage exposing (ProjectStorage)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId, SourceIdStr)
import Models.Project.SourceName exposing (SourceName)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableRow as TableRow exposing (TableRow)
import Models.Project.TableStats exposing (TableStats)
import Models.ProjectInfo exposing (ProjectInfo)
import Models.RelationStyle exposing (RelationStyle)
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Components.EmbedSourceParsingDialog as EmbedSourceParsingDialog
import PagesComponents.Organization_.Project_.Components.ExportDialog as ExportDialog
import PagesComponents.Organization_.Project_.Components.LlmGenerateSqlDialog as LlmGenerateSqlDialog
import PagesComponents.Organization_.Project_.Components.ProjectSaveDialog as ProjectSaveDialog
import PagesComponents.Organization_.Project_.Components.ProjectSharing as ProjectSharing
import PagesComponents.Organization_.Project_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Organization_.Project_.Models.ColorMsg exposing (ColorMsg)
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode exposing (CursorMode)
import PagesComponents.Organization_.Project_.Models.DragState exposing (DragState)
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Organization_.Project_.Models.ErdConf as ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.FindPathDialog exposing (FindPathDialog)
import PagesComponents.Organization_.Project_.Models.HideColumns exposing (HideColumns)
import PagesComponents.Organization_.Project_.Models.LinkLayout exposing (LinkLayout)
import PagesComponents.Organization_.Project_.Models.LinkLayoutId exposing (LinkLayoutId)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId exposing (MemoId)
import PagesComponents.Organization_.Project_.Models.NotesMsg exposing (NotesMsg)
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint)
import PagesComponents.Organization_.Project_.Models.ShowColumns exposing (ShowColumns)
import PagesComponents.Organization_.Project_.Models.TagsMsg exposing (TagsMsg)
import PagesComponents.Organization_.Project_.Views.Erd.SelectionBox as SelectionBox
import PagesComponents.Organization_.Project_.Views.Modals.NewLayout as NewLayout
import Ports exposing (JsMsg)
import Services.Toasts as Toasts
import Set exposing (Set)
import Shared exposing (Confirm, Prompt)


type alias Model =
    { conf : ErdConf
    , navbar : NavbarModel
    , erdElem : ErdProps
    , loaded : Bool
    , dirty : Bool
    , saving : Bool
    , erd : Maybe Erd
    , tableStats : Dict TableId (Dict SourceIdStr (Result String TableStats))
    , columnStats : Dict ColumnId (Dict SourceIdStr (Result String ColumnStats))
    , hoverTable : Maybe TableHover
    , hoverTableRow : Maybe TableRowHover
    , cursorMode : CursorMode
    , selectionBox : Maybe SelectionBox.Model
    , newLayout : Maybe NewLayout.Model
    , editNotes : Maybe NotesDialog
    , editTags : Maybe String
    , editGroup : Maybe GroupEdit
    , editMemo : Maybe MemoEdit
    , amlSidebar : Maybe AmlSidebar
    , detailsSidebar : Maybe DetailsSidebar.Model
    , dataExplorer : DataExplorer.Model
    , virtualRelation : Maybe VirtualRelation
    , findPath : Maybe FindPathDialog
    , llmGenerateSql : Maybe LlmGenerateSqlDialog.Model
    , schemaAnalysis : Maybe SchemaAnalysisDialog
    , exportDialog : Maybe ExportDialog.Model
    , sharing : Maybe ProjectSharing.Model
    , save : Maybe ProjectSaveDialog.Model
    , settings : Maybe ProjectSettingsDialog
    , sourceUpdate : Maybe (SourceUpdateDialog.Model Msg)
    , embedSourceParsing : Maybe (EmbedSourceParsingDialog.Model Msg)
    , help : Maybe HelpDialog

    -- global attrs
    , openedDropdown : HtmlId
    , openedPopover : HtmlId
    , contextMenu : Maybe ContextMenu
    , dragging : Maybe DragState
    , toasts : Toasts.Model
    , modal : Maybe ModalDialog
    , confirm : Maybe ConfirmDialog
    , prompt : Maybe PromptDialog
    , openedDialogs : List HtmlId
    , history : List ( Msg, Msg )
    , future : List ( Msg, Msg )
    }


emptyModel : Model
emptyModel =
    { conf = ErdConf.embedDefault
    , navbar = { mobileMenuOpen = False, search = { text = "", active = 0 } }
    , erdElem = ErdProps.zero
    , loaded = False
    , dirty = False
    , saving = False
    , erd = Nothing
    , tableStats = Dict.empty
    , columnStats = Dict.empty
    , hoverTable = Nothing
    , hoverTableRow = Nothing
    , cursorMode = CursorMode.Select
    , selectionBox = Nothing
    , newLayout = Nothing
    , editNotes = Nothing
    , editTags = Nothing
    , editGroup = Nothing
    , editMemo = Nothing
    , amlSidebar = Nothing
    , detailsSidebar = Nothing
    , dataExplorer = DataExplorer.init
    , virtualRelation = Nothing
    , findPath = Nothing
    , llmGenerateSql = Nothing
    , schemaAnalysis = Nothing
    , exportDialog = Nothing
    , sharing = Nothing
    , save = Nothing
    , settings = Nothing
    , sourceUpdate = Nothing
    , embedSourceParsing = Nothing
    , help = Nothing
    , openedDropdown = ""
    , openedPopover = ""
    , contextMenu = Nothing
    , dragging = Nothing
    , toasts = Toasts.init
    , modal = Nothing
    , confirm = Nothing
    , prompt = Nothing
    , openedDialogs = []
    , history = []
    , future = []
    }


type alias NavbarModel =
    { mobileMenuOpen : Bool
    , search : SearchModel
    }


type alias SearchModel =
    { text : String, active : Int }


type alias NotesDialog =
    { id : HtmlId, table : TableId, column : Maybe ColumnPath, initialNotes : Notes, notes : Notes }


type alias GroupEdit =
    { index : Int, content : String }


type alias MemoEdit =
    { id : MemoId, content : String, createMode : Bool }


type alias AmlSidebar =
    { id : HtmlId, selected : Maybe ( SourceId, String ), errors : List ParserError, otherSourcesTableIdsCache : Set TableId }


type alias VirtualRelation =
    { src : Maybe ColumnRef, mouse : Position.Viewport }


type alias SchemaAnalysisDialog =
    { id : HtmlId, opened : HtmlId }


type alias ProjectSettingsDialog =
    { id : HtmlId }


type alias HelpDialog =
    { id : HtmlId, openedSection : String }


type alias ContextMenu =
    { content : Html Msg, position : Position.Viewport, show : Bool }


type alias ModalDialog =
    { id : HtmlId, content : Msg -> String -> Html Msg }


type alias ConfirmDialog =
    { id : HtmlId, content : Confirm Msg }


type alias PromptDialog =
    { id : HtmlId, content : Prompt Msg, input : String }


type Msg
    = ToggleMobileMenu
    | SearchUpdated String
    | SearchClicked String TableId
    | TriggerSaveProject
    | CreateProject ProjectName Organization ProjectStorage
    | UpdateProject
    | MoveProjectTo ProjectStorage
    | RenameProject ProjectName
    | DeleteProject ProjectInfo
    | GoToTable TableId
    | ShowTable TableId (Maybe PositionHint) String
    | ShowTables (List { id : TableId, columns : List ColumnName }) (Maybe PositionHint) String
    | ShowAllTables String
    | HideTable TableId
    | UnHideTable_ Int ErdTableLayout
    | ShowRelatedTables TableId
    | HideRelatedTables TableId
    | ToggleTableCollapse TableId
    | ShowColumn Int ColumnRef
    | HideColumn ColumnRef
    | ShowColumns TableId ShowColumns
    | HideColumns TableId HideColumns
    | SortColumns TableId ColumnOrder
    | SetColumns_ TableId (List ErdColumnProps)
    | ToggleNestedColumn TableId ColumnPath Bool
    | ToggleHiddenColumns TableId
    | SelectItem HtmlId Bool
    | SelectItems_ (List HtmlId)
    | SelectAll
    | CanvasPosition Position.Diagram
    | TableMove TableId Delta
    | TablePosition TableId Position.Grid
    | TableRowPosition TableRow.Id Position.Grid
    | MemoPosition MemoId Position.Grid
    | LinkPosition LinkLayoutId Position.Grid
    | TableOrder TableId Int
    | TableColor TableId Color Bool
    | MoveColumn ColumnRef Int
    | HoverTable TableHover Bool
    | HoverTableRow TableRowHover Bool
    | CreateUserSource SourceName
    | CreateUserSourceWithId Source
    | CreateRelations (List { src : ColumnRef, ref : ColumnRef })
    | RemoveRelations_ SourceId (List { src : ColumnRef, ref : ColumnRef })
    | IgnoreRelation ColumnRef
    | UnIgnoreRelation_ ColumnRef
    | NewLayoutMsg NewLayout.Msg
    | LayoutMsg LayoutMsg
    | FitToScreen
    | SetView_ CanvasProps
    | ArrangeTables AutoLayoutMethod
    | SetLayout_ ErdLayout
    | NotesMsg NotesMsg
    | TagsMsg TagsMsg
    | ColorMsg ColorMsg
    | GroupMsg GroupMsg
    | MemoMsg MemoMsg
    | LinkMsg LinkMsg
    | ShowTableRow RowQuery (Maybe TableRow.SuccessState) (Maybe PositionHint) String
    | DeleteTableRow TableRow.Id
    | UnDeleteTableRow_ Int TableRow
    | TableRowMsg TableRow.Id TableRow.Msg
    | AmlSidebarMsg AmlSidebarMsg
    | DetailsSidebarMsg DetailsSidebar.Msg
    | DataExplorerMsg DataExplorer.Msg
    | VirtualRelationMsg VirtualRelationMsg
    | FindPathMsg FindPathMsg
    | LlmGenerateSqlDialogMsg LlmGenerateSqlDialog.Msg
    | SchemaAnalysisMsg SchemaAnalysisMsg
    | ExportDialogMsg ExportDialog.Msg
    | SharingMsg ProjectSharing.Msg
    | ProjectSaveMsg ProjectSaveDialog.Msg
    | ProjectSettingsMsg ProjectSettingsMsg
    | EmbedSourceParsingMsg EmbedSourceParsingDialog.Msg
    | SourceParsed Source
    | PlanDialogColors PlanDialog.ColorsModel PlanDialog.ColorsMsg
    | HelpMsg HelpMsg
    | CursorMode CursorMode
    | Fullscreen (Maybe HtmlId)
    | OnWheel WheelEvent
    | Zoom ZoomDelta
      -- global messages
    | Focus HtmlId
    | DropdownToggle HtmlId
    | DropdownOpen HtmlId
    | DropdownClose
    | PopoverOpen HtmlId
    | ContextMenuCreate (Html Msg) PointerEvent
    | ContextMenuShow
    | ContextMenuClose
    | DragStart DragId Position.Viewport
    | DragMove Position.Viewport
    | DragEnd Bool Position.Viewport
    | DragCancel
    | Toast Toasts.Msg
    | ConfirmOpen (Confirm Msg)
    | ConfirmAnswer Bool (Cmd Msg)
    | PromptOpen (Prompt Msg) String
    | PromptUpdate String
    | PromptAnswer (Cmd Msg)
    | ModalOpen HtmlId
    | ModalClose Msg
    | CustomModalOpen (Msg -> HtmlId -> Html Msg)
    | CustomModalClose
    | Undo
    | Redo
    | JsMessage JsMsg
    | Batch (List Msg)
    | Send (Cmd Msg)
    | Noop String


type LayoutMsg
    = LLoad String LayoutName
    | LDelete LayoutName
    | LUnDelete_ LayoutName ErdLayout


type GroupMsg
    = GCreate (List TableId)
    | GEdit Int String
    | GEditUpdate String
    | GEditSave GroupEdit
    | GSetColor Int Color
    | GAddTables Int (List TableId)
    | GRemoveTables Int (List TableId)
    | GDelete Int
    | GUnDelete Int Group


type MemoMsg
    = MCreate Position.Grid
    | MEdit Memo
    | MEditUpdate String
    | MEditSave MemoEdit
    | MSetColor MemoId (Maybe Color)
    | MDelete MemoId
    | MUnDelete Int Memo


type LinkMsg
    = LLCreate Position.Grid LayoutName
    | LLUpdate LinkLayoutId LayoutName
    | LLSetColor LinkLayoutId (Maybe Color)
    | LLDelete LinkLayoutId
    | LLUnDelete Int LinkLayout


type AmlSidebarMsg
    = AOpen (Maybe SourceId)
    | AClose
    | AToggle
    | AChangeSource (Maybe SourceId)
    | AUpdateSource SourceId String
    | AGotSchema SourceId Int (Maybe JsonSchema) (List ParserError)
    | ASourceUpdated SourceId


type VirtualRelationMsg
    = VRCreate (Maybe ColumnRef)
    | VRUpdate ColumnRef Position.Viewport
    | VRMove Position.Viewport
    | VRCancel


type FindPathMsg
    = FPOpen (Maybe TableId) (Maybe TableId)
    | FPToggleSettings
    | FPUpdateFrom String
    | FPUpdateTo String
    | FPSearch
    | FPCompute (Dict TableId ErdTable) (List ErdRelation) TableId TableId FindPathSettings
    | FPToggleResult Int
    | FPSettingsUpdate FindPathSettings
    | FPClose


type SchemaAnalysisMsg
    = SAOpen
    | SASectionToggle HtmlId
    | SAClose


type ProjectSettingsMsg
    = PSOpen
    | PSClose
    | PSSourceToggle Source
    | PSSourceDelete SourceId
    | PSSourceUnDelete_ Int Source
    | PSSourceUpdate SourceUpdateDialog.Msg
    | PSSourceSet Source
    | PSDefaultSchemaUpdate SchemaName
    | PSSchemaToggle SchemaName
    | PSRemoveViewsToggle
    | PSRemovedTablesUpdate String
    | PSHiddenColumnsListUpdate String
    | PSHiddenColumnsMaxUpdate String
    | PSHiddenColumnsPropsToggle
    | PSHiddenColumnsRelationsToggle
    | PSColumnOrderUpdate ColumnOrder
    | PSRelationStyleUpdate RelationStyle
    | PSColumnBasicTypesToggle
    | PSCollapseTableOnShowToggle
    | PSLlmKeyUpdate OpenAIKey
    | PSLlmModelUpdate OpenAIModel


type HelpMsg
    = HOpen String
    | HClose
    | HToggle String


confirm : String -> Html Msg -> Msg -> Msg
confirm title content message =
    ConfirmOpen
        { color = Tw.blue
        , icon = QuestionMarkCircle
        , title = title
        , message = content
        , confirm = "Yes!"
        , cancel = "Nope"
        , onConfirm = message |> T.send
        }


confirmDanger : String -> Html Msg -> Msg -> Msg
confirmDanger title content message =
    ConfirmOpen
        { color = Tw.red
        , icon = QuestionMarkCircle
        , title = title
        , message = content
        , confirm = "Yes!"
        , cancel = "Nope"
        , onConfirm = message |> T.send
        }


prompt : String -> Html Msg -> String -> (String -> Msg) -> Msg
prompt title content input message =
    PromptOpen
        { color = Tw.blue
        , icon = Just QuestionMarkCircle
        , title = title
        , message = content
        , placeholder = ""
        , multiline = False
        , choices = []
        , confirm = "Ok"
        , cancel = "Cancel"
        , onConfirm = message >> T.send
        }
        input


simplePrompt : String -> (String -> Msg) -> Msg
simplePrompt label message =
    PromptOpen
        { color = Tw.blue
        , icon = Just QuestionMarkCircle
        , title = label
        , message = text ""
        , placeholder = ""
        , multiline = False
        , choices = []
        , confirm = "Ok"
        , cancel = "Cancel"
        , onConfirm = message >> T.send
        }
        ""


promptSelect : String -> List String -> String -> (String -> Msg) -> Msg
promptSelect label choices input message =
    PromptOpen
        { color = Tw.blue
        , icon = Just QuestionMarkCircle
        , title = label
        , message = text ""
        , placeholder = ""
        , multiline = False
        , choices = choices
        , confirm = "Ok"
        , cancel = "Cancel"
        , onConfirm = message >> T.send
        }
        input


simplePromptSelect : String -> List String -> (String -> Msg) -> Msg
simplePromptSelect label choices message =
    PromptOpen
        { color = Tw.blue
        , icon = Just QuestionMarkCircle
        , title = label
        , message = text ""
        , placeholder = ""
        , multiline = False
        , choices = choices
        , confirm = "Ok"
        , cancel = "Cancel"
        , onConfirm = message >> T.send
        }
        (choices |> List.head |> Maybe.withDefault "")
